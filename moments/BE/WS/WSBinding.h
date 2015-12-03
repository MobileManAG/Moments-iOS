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
//  WSBinding.h
//  moments
//
//  Created by MobileMan GmbH on 21.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

@import Foundation;
#import "mom_defines.h"

@class CLLocation;
@class User, FBUser, UserNotifications;
@class Stream, StreamMetadata, Location;
@protocol Slice;

@protocol WSBinding <NSObject>

#pragma mark - Authentication

- (void)fbsignin:(FBUser *)fbUser
         success:(void (^)(User * user))success
         failure:(void (^)(NSError *error))failure;


- (void)signout:(void (^)(NSError *error))callback;

- (void)validateToken:(void (^)(NSError *error))callback;

#pragma mark - Broadcast
- (void)startBroadcast:(NSString *)text
              location:(CLLocation *)location
         videoFileName:(NSString *)videoFileName
     thumbnailFileName:(NSString *)thumbnailFileName
                stream:(void (^)(Stream * stream))success
               failure:(void (^)(NSError *error))failure;


- (void)updateStream:(Stream *)stream success:(void (^)(Stream * stream))success failure:(void (^)(NSError *error))failure;
- (void)streamReady:(Stream *)stream success:(void (^)(Stream * stream))success failure:(void (^)(NSError *error))failure;
- (void)streamingStarted:(Stream *)stream success:(void (^)(Stream * stream))success failure:(void (^)(NSError *error))failure;

- (void)stopBroadcast:(Stream *)stream success:(void (^)(Stream * stream))success failure:(void (^)(NSError *error))failure;

- (void)liveBroadcasts:(void (^)(id<Slice> streams))success failure:(void (^)(NSError *error))failure;

- (void)joinBroadcast:(Stream *)stream success:(void (^)(StreamMetadata * metadata))success failure:(void (^)(NSError *error))failure;

- (void)leaveBroadcast:(Stream *)stream success:(void (^)(StreamMetadata * metadata))success failure:(void (^)(NSError *error))failure;

- (void)fetchStreamMetadata:(Stream *)stream timestamp:(NSNumber *)timestamp success:(void (^)(StreamMetadata * metadata))success failure:(void (^)(NSError *error))failure;

- (void)postComment:(Stream *)stream text:(NSString *)text success:(void (^)(void))success failure:(void (^)(NSError *error))failure;

- (void)deleteStream:(Stream *)stream success:(void (^)(Stream * stream))success failure:(void (^)(NSError *error))failure;

#pragma mark - Notifications
- (void)notifications:(User *)user success:(void (^)(UserNotifications * notifications))success failure:(void (^)(NSError *error))failure;

- (void)profile:(NSString *)userId success:(void (^)(User * user))success failure:(void (^)(NSError *error))failure;

#pragma mark - Friends

- (void)friends:(User *)user success:(void (^)(id<Slice> friends))success failure:(void (^)(NSError *error))failure;

- (void)blockFriend:(User *)user success:(void (^)(void))success failure:(void (^)(NSError *error))failure;

- (void)unblockFriend:(User *)user success:(void (^)(void))success failure:(void (^)(NSError *error))failure;

- (void)inviteFriend:(User *)user success:(void (^)(void))success failure:(void (^)(NSError *error))failure;

#pragma mark - PushKit Notifications
- (void)registerTokens:(User *)user  success:(void (^)(void))success failure:(void (^)(NSError *error))failure;

- (void)registerPushNotificationToken:(NSData *)data user:(User *)user  success:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (void)unregisterPushNotificationToken:(User *)user  success:(void (^)(void))success failure:(void (^)(NSError *error))failure;


#pragma mark - Remote Notifications
- (void)registerRemoteNotificationDeviceToken:(NSData *)token user:(User *)user  success:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (void)unregisterRemoteNotificationDeviceToken:(User *)user  success:(void (^)(void))success failure:(void (^)(NSError *error))failure;

#pragma mark - My Moments

- (void)myMoments:(NSString *)userId success:(void (^)(id<Slice> strems))success failure:(void (^)(NSError *error))failure;

@end
