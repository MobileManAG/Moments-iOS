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
//  SystemServiceImpl.m
//  moments
//
//  Created by MobileMan GmbH on 26.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

@import UIKit;
#import <Reachability/Reachability.h>
#import "SystemServiceImpl.h"
//#import <Parse/Parse.h>
#import "MomAWSS3.h"
#import "AFNetworkActivityLogger.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "mom_defines.h"
#import "Settings.h"
#import "WSBindingImpl.h"
#import "ServiceFactory.h"
#import "UserSession.h"
#import "User.h"
#import "FileUtils.h"

NSString *const MOMFriendBroadcastStartedNotification = @"MOMFriendBroadcastStartedNotification";
NSString *const MOMSessionExpiredNotification = @"MOMSessionExpiredNotification";
NSString *const MOMNetworkUnreachableNotification = @"MOMNetworkUnreachableNotification";
NSString *const MOMNetworkReachableNotification = @"MOMNetworkReachableNotification";

@interface SystemServiceImpl ()

@property (nonatomic, strong) Reachability * reachabilityForInternetConnection;
@property (nonatomic, strong) Reachability * reachabilityWithHostName;

@end

@implementation SystemServiceImpl

- (id)init {
    if (self = [super init]) {
        self.wsBinding = [WSBindingImpl instance];
        
        NetworkUnreachable unreachableBlock = ^(Reachability * reachability){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Internet Connection UnReachable");
                [[NSNotificationCenter defaultCenter] postNotificationName:MOMNetworkUnreachableNotification object:reachability];
            });
        };
        
        NetworkReachable reachableBlock = ^(Reachability * reachability){
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Internet Connection Reachable");
                [[NSNotificationCenter defaultCenter] postNotificationName:MOMNetworkReachableNotification object:reachability];
            });
        };
        
        self.reachabilityForInternetConnection = [Reachability reachabilityForInternetConnection];
        self.reachabilityWithHostName = [Reachability reachabilityWithHostName:HOST_NAME];
        
        self.reachabilityForInternetConnection.reachableBlock = reachableBlock;
        self.reachabilityForInternetConnection.unreachableBlock = unreachableBlock;
        self.reachabilityWithHostName.reachableBlock = reachableBlock;
        self.reachabilityWithHostName.unreachableBlock = unreachableBlock;
        
        [self.reachabilityForInternetConnection startNotifier];
        [self.reachabilityWithHostName startNotifier];
        
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    }
    
    return self;
}

- (void) reachabilityChanged:(NSNotification *)notification
{
    Reachability* curReach = [notification object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    //[self updateInterfaceWithReachability:curReach];
    if (curReach.isReachable) {
        NSLog(@"Reachable");
    } else {
        NSLog(@"UnReachable");
    }
}

- (void)startup:(UIApplication *)application launchOptions:(NSDictionary *)launchOptions {
    
    //[Parse setApplicationId:@"APPID" clientKey:@"KEY"];
    
    [self registerForRemoteNotifications:application];

    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
        
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelWarn];
    
    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];

    if (application.applicationState != UIApplicationStateBackground) {
        // Track an app open here if we launch with a push, unless
        // "content_available" was used to trigger a background push (introduced
        // in iOS 7). In that case, we skip tracking here to avoid double
        // counting the app-open.
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
            //[PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        }
    }
    
    if ([PKPushRegistry class]) {
        self.pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        self.pushRegistry.delegate = self;
        self.pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    }
    
    NSError * error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[FileUtils streamsDirectory] error:&error];
    if (error) {
        NSLog(@"Error while removing streams directory: %@", error);
    }
    
    //NSLog(@"PARSE ID: %@", [[PFInstallation currentInstallation] installationId]);
}

- (void)applicationDidBecomeActive {
    [FBSDKAppEvents activateApp];
    /*
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
     */
}

#pragma mark - Remote Notifications
- (void)registerForRemoteNotifications:(UIApplication *)application {
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        
        UIMutableUserNotificationAction *watchAction = [[UIMutableUserNotificationAction alloc] init];
        watchAction.identifier = NOTIFICATION_ACTION_WATCH;
        watchAction.title = NSLocalizedString(@"kLabelWatch", @"kLabelWatch");
        watchAction.activationMode = UIUserNotificationActivationModeForeground;
        watchAction.destructive = NO;
        watchAction.authenticationRequired = YES;
        
        UIMutableUserNotificationAction *passAction = [[UIMutableUserNotificationAction alloc] init];
        passAction.identifier = NOTIFICATION_ACTION_PASS;
        passAction.title = NSLocalizedString(@"kLabelPass", @"kLabelPass");
        passAction.activationMode = UIUserNotificationActivationModeBackground;
        passAction.destructive = NO;
        passAction.authenticationRequired = NO;
        
        UIMutableUserNotificationCategory *passWatchActionsCategory = [[UIMutableUserNotificationCategory alloc] init];
        passWatchActionsCategory.identifier = NOTIFICATION_CATEGORY_PASS_WATCH;
        [passWatchActionsCategory setActions:@[watchAction, passAction] forContext:UIUserNotificationActionContextDefault];
        [passWatchActionsCategory setActions:@[watchAction, passAction] forContext:UIUserNotificationActionContextMinimal];
        
        UIUserNotificationSettings *currentNotifSettings = [UIApplication sharedApplication].currentUserNotificationSettings;
        UIUserNotificationType notifTypes = currentNotifSettings.types;
        if (notifTypes == 0) {
            notifTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        }
        
        UIUserNotificationSettings *newNotifSettings = [UIUserNotificationSettings settingsForTypes:notifTypes categories:[NSSet setWithObject:passWatchActionsCategory]];
        [application registerUserNotificationSettings:newNotifSettings];
        [application registerForRemoteNotifications];
    } else {
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [application registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
#pragma GCC diagnostic warning "-Wdeprecated-declarations"
    }
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
#endif

}

- (void)deviceTokenReceived:(NSData *)deviceToken {
    
    [Settings setDeviceToken:deviceToken];
    /*
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
    */
    UserSession * session = [Settings currentSession];
    if (session.user) {
        [self.wsBinding registerRemoteNotificationDeviceToken:deviceToken user:session.user success:^(void) {
            
        } failure:^(NSError *error) {
            
        }];
    }
    
}

- (void)notifyBroadcastStarted:(NSDictionary *)userInfo completionHandler:(void (^)(void))completionHandler {
    [self notifyBroadcastStarted:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {
        if (completionHandler) {
            completionHandler();
        }
    }];
}

- (NSDictionary *)parseBroadcastNotificationData:(NSDictionary *)userInfo {
    NSDictionary * aps = userInfo[@"aps"];
    NSString * title = @"";
    if ([aps[@"alert"] isKindOfClass:NSString.class]) {
        //[PFPush handlePush:userInfo];
        title = aps[@"alert"];
    } else {
        title = [aps[@"alert"] objectForKey:@"body"];
        if (title == nil) {
            
        }
    }
    
    if ([title isKindOfClass:NSNull.class]) {
        title = @"";
    }
    
    NSString * userId = userInfo[@"userId"];
    NSString * userName = userInfo[@"userName"];
    NSString * fbid = userInfo[@"fbid"];
    NotificationType type = [userInfo[@"type"] intValue];
    NSString * action = userInfo[@"action"];
    NSDictionary * data = @{
                            @"userId" : userId,
                            @"title" : title.length ? title : @"",
                            @"userName" : userName.length ? userName : @"",
                            @"facebookId" : fbid.length ? fbid : @"",
                            @"type" : @(type),
                            @"action" : action.length ? action : @""
                            };
    
    return data;
}

- (void)notifyBroadcastStarted:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler {
    
    [UIApplication sharedApplication].applicationIconBadgeNumber--;
    
    NSDictionary * data = [self parseBroadcastNotificationData:userInfo];
    NotificationType type = [data[@"type"] intValue];
    UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultNoData;
    switch (type) {
        case kNotificationTypeBroadcastStarted: {
            fetchResult = UIBackgroundFetchResultNewData;
            [[NSNotificationCenter defaultCenter] postNotificationName:MOMFriendBroadcastStartedNotification object:nil userInfo:data];
            break;
        }
        default:
            break;
    }
    
    if (handler) {
        handler(fetchResult);
    }
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler {
    
    UIApplication * application = [UIApplication sharedApplication];
    UIApplicationState appState = application.applicationState;
    if (appState == UIApplicationStateInactive) {
        // The application was just brought from the background to the foreground,
        // so we consider the app as having been "opened by a push notification."
        //[PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    
    [UIApplication sharedApplication].applicationIconBadgeNumber--;
    
    if (userInfo[@"type"]) {
        NotificationType type = [userInfo[@"type"] intValue];
        switch (type) {
            case kNotificationTypeBroadcastStarted: {
                [self notifyBroadcastStarted:userInfo fetchCompletionHandler:handler];
                
            }
                break;
            default:
                if (handler) {
                    handler(UIBackgroundFetchResultNoData);
                }
                break;
        }
    } else {
        if (handler) {
            handler(UIBackgroundFetchResultNoData);
        }
    }

}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {
    if ([identifier isEqualToString:NOTIFICATION_ACTION_WATCH]) {
        NotificationType type = [userInfo[@"type"] intValue];
        NSMutableDictionary *userInfoMutable = [userInfo mutableCopy];
        switch (type) {
            case kNotificationTypeBroadcastStarted: {
                [userInfoMutable setObject:NOTIFICATION_ACTION_WATCH forKey:@"action"];
                [self notifyBroadcastStarted:userInfoMutable fetchCompletionHandler:^(UIBackgroundFetchResult result) {
                    completionHandler();
                }];
                
                return;
            }
                break;
            default:
                break;
        }
    } else if ([identifier isEqualToString:NOTIFICATION_ACTION_PASS]) {
        
    } else if (identifier == nil) {
        
    }
    
    [UIApplication sharedApplication].applicationIconBadgeNumber--;
    
    completionHandler();
}

#pragma mark - PKPushKit
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    [Settings setPushNotificationToken:credentials.token];
    UserSession * session = [Settings currentSession];
    if (session.user) {
        [self.wsBinding registerPushNotificationToken:credentials.token user:session.user success:^(void) {
            
        } failure:^(NSError *error) {
            
        }];
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    
}


- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(NSString *)type {
    UserSession * session = [Settings currentSession];
    if (session.user) {
        [self.wsBinding unregisterPushNotificationToken:session.user success:^(void) {
            
        } failure:^(NSError *error) {
            
        }];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

@end
