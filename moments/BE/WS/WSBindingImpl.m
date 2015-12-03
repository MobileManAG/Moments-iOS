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
//  WSBindingImpl.m
//  moments
//
//  Created by MobileMan GmbH on 21.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "WSBindingImpl.h"

@import CoreLocation;

#import "mom_defines.h"
#import "mom_notifications.h"
#import "Settings.h"
#import <Mantle/Mantle.h>
//#import <Parse/Parse.h>

#import "HTTPRequestAuthenticationSSL.h"
#import "FBUser.h"

#import "User.h"
#import "UserAccount.h"
#import "UserNotifications.h"
#import "Stream.h"
#import "Location.h"
#import "StreamMetadata.h"
#import "Comment.h"
#import "Friend.h"

#import "ErrorUtils.h"
#import "UserSession.h"
#import "SliceImpl.h"

static NSString* const kAPIClientErrorDomain = @"kAPIClientErrorDomain";

@implementation WSBindingImpl

#pragma mark - Init
- (NSString *)authPath:(NSString *)params {
    NSString * path = [NSString stringWithFormat:@"%@/%@/%@/%@", WS_API_ROOT_PART, WS_API_AUTH_PART, WS_API_VERSION_PART, params];
    return path;
}

- (NSString *)noauthPath:(NSString *)params {
    NSString * path = [NSString stringWithFormat:@"%@/%@/%@/%@", WS_API_ROOT_PART, WS_API_NOAUTH_PART, WS_API_VERSION_PART, params];
    return path;
}

- (instancetype) init {
    NSURL *url = [Settings apiURLBase];
    if (self = [super initWithBaseURL:url]) {
        self.sslAuth = [HTTPRequestAuthenticationSSL new];
        self.requestSerializer = [AFJSONRequestSerializer new];
        self.requestSerializer.timeoutInterval = DEFAULT_WS_REQUEST_TIMEOUT;
        [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
#ifdef DEBUG
        AFSecurityPolicy * policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        policy.validatesCertificateChain = NO;
        policy.allowInvalidCertificates = YES;
        policy.validatesDomainName = NO;
        policy.pinnedCertificates = [HTTPRequestAuthenticationSSL validationCertificates];
#else
        AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        policy.validatesCertificateChain = NO;
        policy.allowInvalidCertificates = NO;
        policy.validatesDomainName = YES;
        policy.pinnedCertificates = [HTTPRequestAuthenticationSSL validationCertificates];
#endif
        
        self.securityPolicy = policy;
    }
    
    return self;
}

+ (instancetype) instance {
    static WSBindingImpl *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[WSBindingImpl alloc] init];
    });
    return _instance;
}

- (void) checkOAuthCredentialsWithCallback:(void (^)())success failure:(void (^)(NSError *error))failure {
    if (success) {
        success(YES, nil);
    }
    
}

#pragma mark - Helper

- (NSString*) serializeExtraInfo:(NSDictionary*)extraInfo {
    if (!extraInfo) {
        return nil;
    }
    
    if ([NSJSONSerialization isValidJSONObject:extraInfo]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:extraInfo options:NSJSONWritingPrettyPrinted error:nil];
        NSString *extraInfo = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return extraInfo;
    }
    
    return nil;
}

- (void) parseDeletePath:(NSString*)path parameters:(NSDictionary*)parameters callbackBlock:(void (^)(NSDictionary *responseDictionary, NSError *error))callbackBlock {
    UserSession * session = [Settings currentSession];
    //[self.requestSerializer setValue:session.user.facebookID forHTTPHeaderField:@"auth"];
    if (session.user.uuid.length) {
        [self.requestSerializer setAuthorizationHeaderFieldWithUsername:session.user.uuid password:session.user.uuid];
    } else {
        [self.requestSerializer clearAuthorizationHeader];
    }
    
    [self DELETE:path parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        if (!responseObject) {
            callbackBlock(nil, nil);
            return;
        }
        
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *responseDictionary = (NSDictionary*)responseObject;
            NSNumber *successValue = [responseDictionary objectForKey:@"success"];
            if (successValue && ![successValue boolValue]) {
                if (callbackBlock) {
                    callbackBlock(nil, [NSError errorWithDomain:kAPIClientErrorDomain code:105 userInfo:responseDictionary]);
                }
                return;
            }
            if (callbackBlock) {
                callbackBlock(responseDictionary, nil);
                return;
            }
        } else {
            if (callbackBlock) {
                NSError *error = [NSError errorWithDomain:kAPIClientErrorDomain code:103 userInfo:@{NSLocalizedDescriptionKey: @"Bad request", @"response": responseObject}];
                callbackBlock(nil, error);
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [ErrorUtils handleUnauthorizedRequestError:error];
        if (callbackBlock) {
            callbackBlock(nil, error);
        }
    }];
}

- (void) parsePostPath:(NSString*)path parameters:(NSDictionary*)parameters callbackBlock:(void (^)(NSDictionary *responseDictionary, NSError *error))callbackBlock {
    UserSession * session = [Settings currentSession];
    //[self.requestSerializer setValue:session.user.facebookID forHTTPHeaderField:@"auth"];
    if (session.user.uuid.length) {
        [self.requestSerializer setAuthorizationHeaderFieldWithUsername:session.user.uuid password:session.user.uuid];
    } else {
        [self.requestSerializer clearAuthorizationHeader];
    }
    
    [self POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        if (!responseObject) {
            callbackBlock(nil, nil);
            return;
        }
        
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *responseDictionary = (NSDictionary*)responseObject;
            NSNumber *successValue = [responseDictionary objectForKey:@"success"];
            if (successValue && ![successValue boolValue]) {
                if (callbackBlock) {
                    callbackBlock(nil, [NSError errorWithDomain:kAPIClientErrorDomain code:105 userInfo:responseDictionary]);
                }
                return;
            }
            if (callbackBlock) {
                callbackBlock(responseDictionary, nil);
                return;
            }
        } else {
            if (callbackBlock) {
                NSError *error = [NSError errorWithDomain:kAPIClientErrorDomain code:103 userInfo:@{NSLocalizedDescriptionKey: @"Bad request", @"response": responseObject}];
                callbackBlock(nil, error);
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [ErrorUtils handleUnauthorizedRequestError:error];
        if (callbackBlock) {
            callbackBlock(nil, error);
        }
    }];
}

- (void) parsePutPath:(NSString*)path parameters:(NSDictionary*)parameters callbackBlock:(void (^)(NSDictionary *responseDictionary, NSError *error))callbackBlock {
    UserSession * session = [Settings currentSession];
    if (session.user.uuid.length) {
        [self.requestSerializer setAuthorizationHeaderFieldWithUsername:session.user.uuid password:session.user.uuid];
    } else {
        [self.requestSerializer clearAuthorizationHeader];
    }
    
    [self PUT:path parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        if (!responseObject) {
            callbackBlock(nil, nil);
            return;
        }
        
        if (task.error) {
            callbackBlock(nil, task.error);
            return;
        }
        
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *responseDictionary = (NSDictionary*)responseObject;
            callbackBlock(responseDictionary, nil);
        } else {
            if (callbackBlock) {
                NSError *error = [NSError errorWithDomain:kAPIClientErrorDomain code:103 userInfo:@{NSLocalizedDescriptionKey: @"Bad request", @"response": responseObject}];
                callbackBlock(nil, error);
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [ErrorUtils handleUnauthorizedRequestError:error];
        if (callbackBlock) {
            callbackBlock(nil, error);
        }
    }];
}

- (void) parseGetPath:(NSString*)path parameters:(NSDictionary*)parameters callbackBlock:(void (^)(NSDictionary *responseDictionary, NSError *error))callbackBlock {
    UserSession * session = [Settings currentSession];
    if (session.user.uuid.length) {
        [self.requestSerializer setAuthorizationHeaderFieldWithUsername:session.user.uuid password:session.user.uuid];
    } else {
        [self.requestSerializer clearAuthorizationHeader];
    }
    
    [self GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        if (!responseObject) {
            callbackBlock(nil, nil);
            return;
        }
        
        if (task.error) {
            callbackBlock(nil, task.error);
            return;
        }
        
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *data = (NSDictionary*)responseObject;
            callbackBlock(data, nil);
        } else {
            if (callbackBlock) {
                NSError *error = [NSError errorWithDomain:kAPIClientErrorDomain code:103 userInfo:@{NSLocalizedDescriptionKey: @"Bad request", @"response": responseObject}];
                callbackBlock(nil, error);
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [ErrorUtils handleUnauthorizedRequestError:error];
        
        if (callbackBlock) {
            callbackBlock(nil, error);
        }
    }];
}

#pragma mark - API

- (void)fbsignin:(FBUser *)fbUser
         success:(void (^)(User * user))success
         failure:(void (^)(NSError *error))failure {
    
    if (fbUser.token.length == 0) {
        failure([ErrorUtils createWrongParameterError:@"FB token"]);
        return;
    }
    
    if (fbUser.facebookID.length == 0) {
        failure([ErrorUtils createWrongParameterError:@"Facebook ID"]);
        return;
    }
    
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        if (fbUser.email) {
            parameters[@"email"] = fbUser.email;
        }
        
        if (fbUser.name) {
            parameters[@"userName"] = fbUser.name;
        }
        
        if (fbUser.firstName) {
            parameters[@"firstName"] = fbUser.firstName;
        }
        
        if (fbUser.lastName) {
            parameters[@"lastName"] = fbUser.lastName;
        }
        
        if (fbUser.lastName) {
            parameters[@"lastName"] = fbUser.lastName;
        }
        
        parameters[@"token"] = fbUser.token;
        parameters[@"facebookID"] = fbUser.facebookID;
        parameters[@"account_type"] = @(kMomentsAuthTypeFacebook);
        parameters[@"gender"] = @([FBUser genderFromFBGender:fbUser.gender]);
        parameters[@"device"] = @{@"deviceType":@(kDeviceTypeIOS)};
        
        /*
        if ([[[PFInstallation currentInstallation] installationId] length]) {
            parameters[@"pushNotificationID"] = [[PFInstallation currentInstallation] installationId];
        }
         */
        
        if ([[Settings deviceToken] length]) {
            parameters[@"deviceToken"] = [Settings deviceTokenToString];
        }
        
        if ([[Settings pushNotificationToken] length]) {
            parameters[@"pushNotificationToken"] = [Settings pushNotificationTokenToString];
        }
        

        [self parsePostPath:[self noauthPath:@"users/signin"] parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
            if (error) {
                failure(error);
                return;
            }
            
            UserAccount * account = [MTLJSONAdapter modelOfClass:[UserAccount class] fromJSONDictionary:responseDictionary[@"account"] error:&error];
            
            User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:responseDictionary error:&error];
            user.account = account;
            
            success(user);
        }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)signout:(void (^)(NSError *error))callback {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parsePostPath:[self authPath:@"users/signout"] parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
            if (error) {
                callback(error);
                return;
            }
            
            callback(nil);
        }];
        
    } failure:^(NSError *error) {
        callback(error);
    }];
}

- (void)validateToken:(void (^)(NSError *error))callback {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parseGetPath:[self authPath:@"users/token/validate"] parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
            if (error) {
                callback(error);
                return;
            }
            
            callback(nil);
        }];
        
    } failure:^(NSError *error) {
        callback(error);
    }];
}

#pragma mark - Broadcast
- (void)startBroadcast:(NSString *)text
              location:(CLLocation *)location
         videoFileName:(NSString *)videoFileName
     thumbnailFileName:(NSString *)thumbnailFileName
                stream:(void (^)(Stream * stream))success
               failure:(void (^)(NSError *error))failure {
    
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        if (text.length) {
            parameters[@"text"] = text;
        }
        
        if (videoFileName.length) {
            parameters[@"videoFileName"] = videoFileName;
        }
        
        if (thumbnailFileName.length) {
            parameters[@"thumbnailFileName"] = thumbnailFileName;
        }
        
        if (location) {
            parameters[@"location"] = @{
                                        @"longitude": @(location.coordinate.longitude),
                                        @"latitude": @(location.coordinate.latitude)
                                        };
        }
        
        [self parsePostPath:[self authPath:@"streams/start"] parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
            if (error) {
                failure(error);
                return;
            }
            
            Stream * stream = [self parseStreamFromStreamData:responseDictionary failure:nil];
            success(stream);
        }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)updateStream:(Stream *)stream success:(void (^)(Stream * stream))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];        
        if (stream.location) {
            parameters[@"location"] = @{@"longitude":@(stream.location.longitude), @"latitude":@(stream.location.latitude)};
        }
        
        
        [self parsePutPath:[self authPath:[NSString stringWithFormat:@"streams/%@", stream.uuid]]
                parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
                    
            if (error) {
                failure(error);
                return;
            }
            
            Stream * stream = [self parseStreamFromStreamData:responseDictionary failure:nil];
            success(stream);
        }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)streamReady:(Stream *)stream success:(void (^)(Stream * stream))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parsePutPath:[self authPath:[NSString stringWithFormat:@"streams/%@/ready", stream.uuid]]
                parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
                    
                    if (error) {
                        failure(error);
                        return;
                    }
                    
                    Stream * stream = [self parseStreamFromStreamData:responseDictionary failure:nil];
                    success(stream);
                }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)streamingStarted:(Stream *)stream success:(void (^)(Stream * stream))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        parameters[@"state"] = @(stream.state);
        
        if (stream.location) {
            parameters[@"location"] = @{@"longitude":@(stream.location.longitude), @"latitude":@(stream.location.latitude)};
        }
        
        
        [self parsePutPath:[self authPath:[NSString stringWithFormat:@"streams/%@/streaming", stream.uuid]]
                parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
                    
                    if (error) {
                        failure(error);
                        return;
                    }
                    
                    Stream * stream = [self parseStreamFromStreamData:responseDictionary failure:nil];
                    success(stream);
                }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)stopBroadcast:(Stream *)stream success:(void (^)(Stream * stream))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parsePostPath:[self authPath:[NSString stringWithFormat:@"streams/%@/stop", stream.uuid]] parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
            if (error) {
                failure(error);
                return;
            }
            
            Stream * stream = [self parseStreamFromStreamData:responseDictionary failure:nil];
            success(stream);
        }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (Stream *)parseStreamFromStreamData:(NSDictionary *)streamData failure:(void (^)(NSError *error))failure {
    
    NSError * error = nil;
    Stream * stream = [MTLJSONAdapter modelOfClass:[Stream class] fromJSONDictionary:streamData error:&error];
    if (error) {
        if (failure) {
            failure(error);
        }
        
        return nil;
    }
    
    if ([streamData objectForKey:@"location"]) {
        Location * location = [MTLJSONAdapter modelOfClass:[Location class] fromJSONDictionary:[streamData objectForKey:@"location"] error:&error];
        if (error) {
            if (failure) {
                failure(error);
            }
            
            return nil;
        }
        
        stream.location = location;
    }
    
    return stream;
}

- (Stream *)parseStreamFromUserData:(NSDictionary *)userData failure:(void (^)(NSError *error))failure {
    return [self parseStreamFromStreamData:userData[@"stream"] failure:failure];
}

- (void)liveBroadcasts:(void (^)(id<Slice> streams))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parseGetPath:[self authPath:@"streams/live"] parameters:parameters callbackBlock:^(NSDictionary * data, NSError * _error) {
            if (_error) {
                failure(_error);
                return;
            }
            
            __block NSError * error = nil;
            SliceImpl * streams = [MTLJSONAdapter modelOfClass:[SliceImpl class] fromJSONDictionary:data error:&error];
            if (error) {
                failure(error);
                return;
            }
            
            NSMutableArray * users = [NSMutableArray arrayWithCapacity:streams.numberOfElements.intValue];
            for (NSDictionary * userData in data[@"content"]) {
                
                User * user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:userData error:&error];
                Stream * stream = [self parseStreamFromStreamData:userData[@"stream"] failure:^(NSError *_error) {
                    error = _error;
                }];
                
                if (!error) {
                    user.stream = stream;
                } else {
                    user.stream = nil;
                    LogError(@"Error while parsing data: %@", error);
                }
                
                [users addObject:user];
            }

            streams.content = users;
            success(streams);
        }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)joinBroadcast:(Stream *)stream success:(void (^)(StreamMetadata * metadata))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parsePutPath:[self authPath:[NSString stringWithFormat:@"streams/%@/join", stream.uuid]]
                parameters:parameters callbackBlock:^(NSDictionary *streamMetadataDictionary, NSError *error) {
                    
                    if (error) {
                        failure(error);
                        return;
                    }
                    
                    StreamMetadata * metadata = [StreamMetadata createFromJSON:streamMetadataDictionary];
                    success(metadata);
                }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)leaveBroadcast:(Stream *)stream success:(void (^)(StreamMetadata * metadata))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parsePutPath:[self authPath:[NSString stringWithFormat:@"streams/%@/leave", stream.uuid]]
                parameters:parameters callbackBlock:^(NSDictionary *streamMetadataDictionary, NSError *error) {
                    
                    if (error) {
                        failure(error);
                        return;
                    }
                    
                    StreamMetadata * metadata = [StreamMetadata createFromJSON:streamMetadataDictionary];
                    success(metadata);
                }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)fetchStreamMetadata:(Stream *)stream timestamp:(NSNumber *)timestamp success:(void (^)(StreamMetadata * metadata))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        NSString * path = nil;
        if (timestamp) {
            path = [NSString stringWithFormat:@"streams/%@/metadata/%lld", stream.uuid, timestamp.longLongValue];
        } else {
            path = [NSString stringWithFormat:@"streams/%@/metadata", stream.uuid];
        }
        
        [self parseGetPath:[self authPath:path] parameters:parameters callbackBlock:^(NSDictionary *streamMetadataDictionary, NSError *error) {
                    
            if (error) {
                failure(error);
                return;
            }
            
            StreamMetadata * metadata = [StreamMetadata createFromJSON:streamMetadataDictionary];
            success(metadata);
        }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)postComment:(Stream *)stream text:(NSString *)text success:(void (^)(void))success failure:(void (^)(NSError *error))failure {
    
    if (text.length == 0) {
        failure([ErrorUtils createWrongParameterError:@"text"]);
        return;
    }
    
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        parameters[@"text"] = text;
        [self parsePostPath:[self authPath:[NSString stringWithFormat:@"streams/%@/comment", stream.uuid]]
                parameters:parameters callbackBlock:^(NSDictionary *streamMetadataDictionary, NSError *error) {
                    
                    if (error) {
                        failure(error);
                        return;
                    }
                    
                    success();
                }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)deleteStream:(Stream *)stream success:(void (^)(Stream * stream))success failure:(void (^)(NSError *error))failure {

    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parseDeletePath:[self authPath:[NSString stringWithFormat:@"streams/%@", stream.uuid]]
                 parameters:parameters callbackBlock:^(NSDictionary *streamMetadataDictionary, NSError *error) {
                     
                     if (error) {
                         failure(error);
                         return;
                     }
                     
                     success(stream);
                 }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

#pragma mark - PushKit Notifications

- (void)registerTokens:(User *)user  success:(void (^)(void))success failure:(void (^)(NSError *error))failure {
    if ([Settings deviceToken] || [Settings pushNotificationToken]) {
        [self checkOAuthCredentialsWithCallback:^{
            
            NSMutableDictionary * parameters = [NSMutableDictionary new];
            if ([[Settings deviceToken] length]) {
                parameters[@"deviceToken"] = [Settings deviceTokenToString];
            }
            
            if ([[Settings pushNotificationToken] length]) {
                parameters[@"pushNotificationToken"] = [Settings pushNotificationTokenToString];
            }
            
            if (parameters.count) {
                [self parsePutPath:[self authPath:@"users/tokens"] parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
                    
                    if (error) {
                        failure(error);
                        return;
                    }
                    
                    success();
                }];
            }
            
        } failure:^(NSError *error) {
            failure(error);
        }];
    }
}

- (void)registerPushNotificationToken:(NSData *)data user:(User *)user  success:(void (^)(void))success failure:(void (^)(NSError *error))failure {
    [self registerTokens:user success:success failure:failure];
}

- (void)unregisterPushNotificationToken:(User *)user  success:(void (^)(void))success failure:(void (^)(NSError *error))failure {
    
}

#pragma mark - Remote Notifications
- (void)registerRemoteNotificationDeviceToken:(NSData *)token user:(User *)user  success:(void (^)(void))success failure:(void (^)(NSError *error))failure {
    [self registerTokens:user success:success failure:failure];
}

- (void)unregisterRemoteNotificationDeviceToken:(User *)user  success:(void (^)(void))success failure:(void (^)(NSError *error))failure {
    
}

#pragma mark - Friends

- (void)friends:(User *)user success:(void (^)(id<Slice> friends))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parseGetPath:[self authPath:@"friends"] parameters:parameters callbackBlock:^(NSDictionary *data, NSError *error) {
                    
            if (error) {
                failure(error);
                return;
            }
            
            SliceImpl * friends = [MTLJSONAdapter modelOfClass:[SliceImpl class] fromJSONDictionary:data error:&error];
            
            NSMutableArray * content = [NSMutableArray arrayWithCapacity:friends.numberOfElements.intValue];
            for (NSDictionary * friendData in data[@"content"]) {
                Friend * friend = [MTLJSONAdapter modelOfClass:[Friend class] fromJSONDictionary:friendData error:&error];
                [content addObject:friend];
            }
            
            friends.content = content;
            success(friends);
            
        }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)blockFriend:(User *)user success:(void (^)(void))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parsePutPath:[self authPath:[NSString stringWithFormat:@"friends/%@/block/%@", user.uuid, @"true"]] parameters:parameters callbackBlock:^(NSDictionary *data, NSError *error) {
            
            if (error) {
                failure(error);
                return;
            }
            
            success();
            
        }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)unblockFriend:(User *)user success:(void (^)(void))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parsePutPath:[self authPath:[NSString stringWithFormat:@"friends/%@/block/%@", user.uuid, @"false"]] parameters:parameters callbackBlock:^(NSDictionary *data, NSError *error) {
            
            if (error) {
                failure(error);
                return;
            }
            
            success();
            
        }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)inviteFriend:(User *)user success:(void (^)(void))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parsePutPath:[self authPath:[NSString stringWithFormat:@"friends/%@/invite", user.facebookID]] parameters:parameters callbackBlock:^(NSDictionary *data, NSError *error) {
            
            if (error) {
                failure(error);
                return;
            }
            
            success();
            
        }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}


#pragma mark - Notifications
- (void)notifications:(User *)user success:(void (^)(UserNotifications * notifications))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parseGetPath:[self authPath:@"users/notifications"] parameters:parameters callbackBlock:^(NSDictionary *data, NSError *error) {
            
            if (error) {
                failure(error);
                return;
            }
            
            UserNotifications * notifications = [MTLJSONAdapter modelOfClass:[UserNotifications class] fromJSONDictionary:data error:&error];
            success(notifications);
            
        }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}


- (void)profile:(NSString *)userId success:(void (^)(User * user))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parseGetPath:[self authPath:[NSString stringWithFormat:@"users/profile/%@", userId]] parameters:parameters callbackBlock:^(NSDictionary *data, NSError *error) {
            
            if (error) {
                failure(error);
                return;
            }
            
            User * user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:data error:&error];
            Stream * stream = [self parseStreamFromStreamData:data[@"stream"] failure:nil];
            user.stream = stream;
            success(user);
            
        }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

#pragma mark - My Moments

- (void)myMoments:(NSString *)userId success:(void (^)(id<Slice> strems))success failure:(void (^)(NSError *error))failure {
    [self checkOAuthCredentialsWithCallback:^{
        
        NSMutableDictionary * parameters = [NSMutableDictionary new];
        [self parseGetPath:[self authPath:@"users/moments"] parameters:parameters callbackBlock:^(NSDictionary * data, NSError * _error) {
            if (_error) {
                failure(_error);
                return; 
            }

            if (data == nil) {
                success([SliceImpl createEmpty]);
            }
            
            __block NSError * error = nil;
            SliceImpl * slice = [MTLJSONAdapter modelOfClass:[SliceImpl class] fromJSONDictionary:data error:&error];
            if (error) {
                failure(error);
                return;
            }
            
            NSMutableArray * streams = [NSMutableArray arrayWithCapacity:slice.numberOfElements.intValue];
            for (NSDictionary * streamData in data[@"content"]) {
                
                User * user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:streamData[@"createdBy"] error:&error];
                Stream * stream = [self parseStreamFromStreamData:streamData failure:^(NSError *_error) {
                    error = _error;
                }];
                
                if (!error) {
                    stream.user = user;
                } else {
                    LogError(@"Error while parsing data: %@", error);
                }
                
                [streams addObject:stream];
            }
            
            slice.content = streams;
            success(slice);
        }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

@end
