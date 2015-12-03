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
//  SystemService.h
//  moments
//
//  Created by MobileMan GmbH on 26.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

@import UIKit;
#import <Reachability/Reachability.h>

@class UIApplication;

@protocol SystemService <NSObject>

- (void)startup:(UIApplication *)application launchOptions:(NSDictionary *)launchOptions;
- (void)applicationDidBecomeActive;

#pragma mark - Remote Notifications
- (void)deviceTokenReceived:(NSData *)deviceToken;
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler;
- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler;
- (void)notifyBroadcastStarted:(NSDictionary *)userInfo completionHandler:(void (^)(void))completionHandler;

- (NSDictionary *)parseBroadcastNotificationData:(NSDictionary *)userInfo;

@end
