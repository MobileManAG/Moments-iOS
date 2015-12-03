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
//  Settings.m
//  moments
//
//  Created by MobileMan GmbH on 21.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "Settings.h"
#import "mom_defines.h"
#import "SSKeychain.h"
#import "UserSession.h"
#import "User.h"
#import "UserAccount.h"

#define WEB_SERVICE_URL_BASE_KEY @"WebServiceURLBase"
#define UD_KEY_SESSION @"userSession"

static NSData * _deviceToken = nil;
static NSData * _pushNotificationToken = nil;
static UserSession * _session = nil;
static NSDictionary * _appLaunchBroadcastNotificationData = nil;


@implementation Settings

+ (void)initialize {
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WEB_SERVICE_URL_BASE_KEY];
    [[NSUserDefaults standardUserDefaults] setValue:API_URL_BASE forKey:WEB_SERVICE_URL_BASE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"];
}

+ (void)setCurrentSession:(UserSession *)session {
    _session = session;
    NSData * sessionData = [NSKeyedArchiver archivedDataWithRootObject:session];
    [[NSUserDefaults standardUserDefaults] setObject:sessionData forKey:UD_KEY_SESSION];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (UserSession *)currentSession {
    if (_session) {
        return _session;
    }
    
    id sessionData = [[NSUserDefaults standardUserDefaults] objectForKey:UD_KEY_SESSION];
    _session = [NSKeyedUnarchiver unarchiveObjectWithData:sessionData];
    if (_session) {
        _session.user.account.password = [SSKeychain passwordForService:MOM_APP_ID account:_session.user.account.email];
    }
    
    return _session;
}

+ (void)removeCurrentSession {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:UD_KEY_SESSION];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _session = nil;
}

+ (NSTimeInterval)sessionTimeout {
    NSTimeInterval sessionTimeout = [[NSUserDefaults standardUserDefaults] doubleForKey:@"sessionTimeout"];
    if (sessionTimeout == 0.0) {
        sessionTimeout = DEFAULT_SESSION_TIMEOUT;
        [[NSUserDefaults standardUserDefaults] setDouble:sessionTimeout forKey:@"sessionTimeout"];
    }
    
    return sessionTimeout;
}

+ (NSURL*)apiURLBase {
    NSString * url = [[NSUserDefaults standardUserDefaults] stringForKey:WEB_SERVICE_URL_BASE_KEY];
    if (url == nil) {
        url = API_URL_BASE;
    }
    
    return [NSURL URLWithString:url];
}

+ (NSString *)deviceTokenToString {
    if (![self deviceToken]) {
        return nil;
    }
    const unsigned *tokenBytes = [[self deviceToken] bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    
    return hexToken;
}

+ (NSData *)deviceToken {
    if (_deviceToken == nil) {
        _deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"];
    }
    
    return _deviceToken;
}

+ (void)setDeviceToken:(NSData *)token {
    _deviceToken = token;
    [[NSUserDefaults standardUserDefaults] setObject:_deviceToken forKey:@"deviceToken"];
}

+ (NSString *)pushNotificationTokenToString {
    if (![self pushNotificationToken]) {
        return nil;
    }
    
    const unsigned *tokenBytes = [[self pushNotificationToken] bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    
    return hexToken;
}


+ (NSData *)pushNotificationToken {
    if (_pushNotificationToken == nil) {
        _pushNotificationToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"pushNotificationToken"];
    }
    
    return _pushNotificationToken;
}

+ (void)setPushNotificationToken:(NSData *)token {
    _pushNotificationToken = token;
    [[NSUserDefaults standardUserDefaults] setObject:_pushNotificationToken forKey:@"pushNotificationToken"];
}

+ (void)setBroadcastFBSharingActive:(BOOL)active {
    [[NSUserDefaults standardUserDefaults] setBool:active forKey:@"broadcastFBSharingActive"];
}

+ (BOOL)broadcastFBSharingActive {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"broadcastFBSharingActive"];
}

+ (void)setAppLaunchBroadcastNotificationData:(NSDictionary *)data {
    _appLaunchBroadcastNotificationData = data;
}


+ (NSDictionary *)getAndClearAppLaunchBroadcastNotificationData {
    NSDictionary * result = _appLaunchBroadcastNotificationData;
    _appLaunchBroadcastNotificationData = nil;
    return result;
}


@end
