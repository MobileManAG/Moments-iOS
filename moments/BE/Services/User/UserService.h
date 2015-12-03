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
//  UserService.h
//  moments
//
//  Created by MobileMan GmbH on 20.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

@class User, UserSession, UserNotifications;
@protocol Slice;

@protocol UserService <NSObject>

- (UserSession *)currentSession;

#pragma mark - Auth
- (void)signin:(void (^)(User * session))success failure:(void (^)(NSError *error))failure;
- (void)signin:(BOOL)withWritePermissions success:(void (^)(User * session))success failure:(void (^)(NSError *error))failure;

- (void)signout:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (void)validateToken:(void (^)(NSError *error))callback;

#pragma mark - Friends
- (void)friends:(void (^)(NSArray * appFriends, NSArray * invitableFriends))success failure:(void (^)(NSError *error))failure;

- (void)blockFriend:(User *)user success:(void (^)(void))success failure:(void (^)(NSError *error))failure;

- (void)unblockFriend:(User *)user success:(void (^)(void))success failure:(void (^)(NSError *error))failure;

#pragma mark - Notifications
- (void)notifications:(User *)user success:(void (^)(UserNotifications * notifications))success failure:(void (^)(NSError *error))failure;

- (void)profile:(NSString *)userId success:(void (^)(User * user))success failure:(void (^)(NSError *error))failure;

#pragma mark - My Moments

- (void)myMoments:(NSString *)userId success:(void (^)(id<Slice> streams))success failure:(void (^)(NSError *error))failure;

@end