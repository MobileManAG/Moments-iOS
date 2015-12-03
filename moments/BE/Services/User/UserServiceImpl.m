/*******************************************************************************
 * Copyright 2015 MobileMan GmbH
 * www.mobileman.com
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ******************************************************************************/

//
//  UserServiceImpl.m
//  moments
//
//  Created by MobileMan GmbH on 20.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "UserServiceImpl.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "Settings.h"
#import "User.h"
#import "UserAccount.h"
#import "FBUser.h"
#import "UserSession.h"
#import "mom_defines.h"
#import "WSBindingImpl.h"
#import "ErrorUtils.h"
#import "Slice.h"
#import "Friend.h"
#import "mom_notifications.h"
#import "NSError+Util.h"

@implementation UserServiceImpl

- (instancetype)init {
    if (self = [super init]) {
        self.wsBinding = [WSBindingImpl instance];
    }
    
    return self;
}

- (UserSession *)currentSession {
    FBSDKAccessToken * token = [FBSDKAccessToken currentAccessToken];
    if (!token) {
        [Settings removeCurrentSession];
        return nil;
    }
    
    UserSession * session = [Settings currentSession];
    return session;
}

- (void)signin:(BOOL)withWritePermissions success:(void (^)(User * session))success failure:(void (^)(NSError *error))failure {
    
    do {
        FBSDKAccessToken * token = [FBSDKAccessToken currentAccessToken];
        if (!token) {
            break;
        }
        
        if (withWritePermissions) {
            if (![token hasGranted:@"publish_actions"]) {
                // not granted - reask for write permissions
                break;
            }
        } else {
            if (![token hasGranted:@"user_friends"] || ![token hasGranted:@"public_profile"]) {
                // not granted - reask for read permissions
                break;
            }
        }
        
        // we have correct token - check user session
        UserSession * session = [self currentSession];
        if (!session) {
            // session missing - siging to backend with valid token
            [self signinWithFacebookInternal:token success:^(UserSession * session) {
                success(session.user);
            } failure:^(NSError *error) {
                failure(error);
            }];
        } else {
            // token and session are ok - success
            success(session.user);
        }
        
        return;
        
    } while (false);
    
    
    
    __block FBSDKLoginManager *manager = [[FBSDKLoginManager alloc] init];
    manager.loginBehavior = FBSDKLoginBehaviorSystemAccount;
    
    FBSDKLoginManagerRequestTokenHandler fbLoginHandler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
            Log(@"FB signin failed: \n%@", error);
            failure(error);
        } else if (result.isCancelled) {
            Log(@"FB signin cancelled");
            NSError * error = [ErrorUtils createError:NSLocalizedString(@"kFBSigninCancelled", @"Facebook signin cancelled") code:kErrorCodeFBSignInCancelled severity:kErrorSeverityInfo];
            failure(error);
        } else {
            FBSDKAccessToken * token = [FBSDKAccessToken currentAccessToken];
            if (withWritePermissions) {
                if (![token hasGranted:@"publish_actions"]) {
                    [manager logInWithPublishPermissions:@[@"publish_actions"] fromViewController:nil handler:fbLoginHandler];
                    return;
                }
                
            } else {
                if (![token hasGranted:@"user_friends"]) {
                    [self signin:withWritePermissions success:success failure:failure];
                    return;
                }
            }
            
            [self signinWithFacebookInternal:token success:^(UserSession * session) {
                success(session.user);
            } failure:^(NSError *error) {
                failure(error);
            }];
        }
    };
    
    FBSDKAccessToken * token = [FBSDKAccessToken currentAccessToken];
    if (withWritePermissions) {
        [manager logInWithPublishPermissions:@[@"publish_actions"] fromViewController:nil handler:fbLoginHandler];
    } else {
        if (token != nil) {
            if (![token hasGranted:@"user_friends"]) {
                [manager logInWithReadPermissions:@[@"user_friends"] fromViewController:nil handler:fbLoginHandler];
            } else {
                [manager logInWithReadPermissions:@[@"user_friends", @"public_profile"] fromViewController:nil  handler:fbLoginHandler];
            }
            
        } else {
            [manager logInWithReadPermissions:@[@"user_friends", @"public_profile"] fromViewController:nil handler:fbLoginHandler];
        }
    }
    
}

- (void)signin:(void (^)(User * user))success failure:(void (^)(NSError *error))failure {
    [self signin:NO success:success failure:failure];
}

- (void)signinWithFacebookInternal:(FBSDKAccessToken *)token success:(void (^)(UserSession * session))success failure:(void (^)(NSError *error))failure {
    
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, NSDictionary * data, NSError *error) {
        if (error) {
            NSLog(@"FB signin failed: \n%@", error);
            failure(error);
            return;
        }
        
        FBUser * user = [FBUser createWithFacebookData:data];
        user.token = token.tokenString;
        
        [self.wsBinding fbsignin:user success:^(User * sysUser) {
            
            UserSession * session = [UserSession createWithUser:sysUser];
            [Settings setCurrentSession:session];            
            success(session);
            
        } failure:^(NSError *error) {
            FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
            [login logOut];
            NSLog(@"%s - signinWithFacebookInternal, signin failed: %@", __PRETTY_FUNCTION__, error);
            failure(error);
        }];
    }];
}

- (void)signout:(void (^)(void))success failure:(void (^)(NSError *error))failure {
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login logOut];
    
    [self.wsBinding signout:^(NSError *error) {
        [Settings removeCurrentSession];
        if (error) {
            failure(error);
        } else {
            success();
        }
        
    }];
}

- (void)validateToken:(void (^)(NSError *error))callback {
    [self.wsBinding validateToken:^(NSError *error) {
        if (error) {
            if ([error isMomentsErrorDomain] || ![error.domain isEqualToString:NSURLErrorDomain]) {
                FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
                [login logOut];
                [Settings removeCurrentSession];
            }
        }
        
        callback(error);
    }];
}

#pragma mark - Friends
- (void)friends:(void (^)(NSArray * friendsWithApp, NSArray * invitableFriends))success failure:(void (^)(NSError *error))failure {
    if (![Settings currentSession]) {
        failure([ErrorUtils createMissingSessionError]);
        return;
    }
    
    [self.wsBinding friends:[[Settings currentSession] user] success:^(id<Slice> friends) {
        
        NSMutableArray * friendsWithApp = [NSMutableArray arrayWithCapacity:friends.numberOfElements.intValue];
        NSMutableArray * invitableFriends = [NSMutableArray arrayWithCapacity:friends.numberOfElements.intValue];
        
        for (Friend * friend in friends.content) {
            if (friend.uuid.length) {
                [friendsWithApp addObject:friend];
            } else {
                [invitableFriends addObject:friend];
            }
        }
        
        success(friendsWithApp, invitableFriends);
        
    } failure:^(NSError *error) {
        if ([ErrorUtils httpStatusCode:error] == 422) {
            error = [ErrorUtils createError:NSLocalizedString(@"kFBSigninCancelled", @"Facebook signin cancelled") code:kErrorCodeFBMissingFriendsPermission severity:kErrorSeverityError];
            [[NSNotificationCenter defaultCenter] postNotificationName:MOMSessionExpiredNotification object:self userInfo:@{@"error":error}];
        }
        
        failure(error);
    }];
}

- (void)blockFriend:(User *)user success:(void (^)(void))success failure:(void (^)(NSError *error))failure {
    if (![Settings currentSession]) {
        failure([ErrorUtils createMissingSessionError]);
        return;
    }
    
    [self.wsBinding blockFriend:user success:^(void) {
        
        success();
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)unblockFriend:(User *)user success:(void (^)(void))success failure:(void (^)(NSError *error))failure {
    if (![Settings currentSession]) {
        failure([ErrorUtils createMissingSessionError]);
        return;
    }
    
    [self.wsBinding unblockFriend:user success:^(void) {
        
        success();
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

#pragma mark - FB invitation
- (void)inviteFriend:(User *)user success:(void (^)(void))success failure:(void (^)(NSError *error))failure {
    if (![Settings currentSession]) {
        failure([ErrorUtils createMissingSessionError]);
        return;
    }
    
    
    FBSDKAppInviteContent *content =[[FBSDKAppInviteContent alloc] init];
    content.appLinkURL = [NSURL URLWithString:@"https://www.mydomain.com/myapplink"];
    content.appInvitePreviewImageURL = [NSURL URLWithString:@"https://www.mydomain.com/my_invite_image.jpg"];
    FBSDKAppInviteDialog * dialog = [[FBSDKAppInviteDialog alloc] init];
    dialog.delegate = self;
    dialog.content = content;

    if ([dialog canShow]) {
        [dialog show];
    }
    // present the dialog. Assumes self implements protocol `FBSDKAppInviteDialogDelegate`
}


- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results {
    /*
    [self.wsBinding inviteFriend:nil success:^(void) {
        
        //success();
        
    } failure:^(NSError *error) {
        //failure(error);
    }];
     */
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error {
    
}

#pragma mark - Notifications
- (void)notifications:(User *)user success:(void (^)(UserNotifications * notifications))success failure:(void (^)(NSError *error))failure {
    [self.wsBinding notifications:user success:^(UserNotifications * notifications) {
        success(notifications);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)profile:(NSString *)userId success:(void (^)(User * user))success failure:(void (^)(NSError *error))failure {
    [self.wsBinding profile:userId success:^(User * user) {
        success(user);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

#pragma mark - My Moments

- (void)myMoments:(NSString *)userId success:(void (^)(id<Slice> strems))success failure:(void (^)(NSError *error))failure {
    [self.wsBinding myMoments:userId success:^(id<Slice> strems) {
        success(strems);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

@end
