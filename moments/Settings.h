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
//  Settings.h
//  moments
//
//  Created by MobileMan GmbH on 21.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UserSession;

@interface Settings : NSObject

+ (UserSession *)currentSession;
+ (void)setCurrentSession:(UserSession *)session;
+ (void)removeCurrentSession;

+ (NSTimeInterval)sessionTimeout;

#pragma mark - API
+ (NSURL*)apiURLBase;

#pragma mark - Device Token

+ (NSString *)deviceTokenToString;
+ (NSData *)deviceToken;
+ (void)setDeviceToken:(NSData *)deviceToken;

+ (NSString *)pushNotificationTokenToString;
+ (NSData *)pushNotificationToken;
+ (void)setPushNotificationToken:(NSData *)deviceToken;

+ (void)setBroadcastFBSharingActive:(BOOL)active;
+ (BOOL)broadcastFBSharingActive;

+ (void)setAppLaunchBroadcastNotificationData:(NSDictionary *)data;
+ (NSDictionary *)getAndClearAppLaunchBroadcastNotificationData;

@end
