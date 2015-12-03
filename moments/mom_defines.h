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
//  mom_defines.h
//  moments
//
//  Created by MobileMan GmbH on 20.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#ifndef moments_mom_defines_h
#define moments_mom_defines_h

#define Log(format, ...) NSLog((@"%d %s " format), __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__);
#define LogError(format, ...) NSLog((@"ERROR %d %s " format), __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__);
#define LogErr(error) LogError(@"%@", error);
#define LogMethodStart Log(@" - start")
#define LogMethodEnd Log(@" - end")
#define LogMethodCancel Log(@" - end (cancel)")

@import UIKit;

#define MOM_APP_ID @"host"
#define MOM_FB_APP_ID @"XXX"

#define WS_API_ROOT_PART @"api"
#define WS_API_AUTH_PART @"auth"
#define WS_API_NOAUTH_PART @"noauth"
#define WS_API_VERSION_PART @"v1"

//

#define PROD

#ifdef PROD

#define HOST_NAME @"prod host"
#define HOST_PROTOCOL @"https"
#define HOST_PORT 443
#define HOST_APP_CONTEXT @""

#elif defined DEV

#define HOST_NAME @"dev host"
#define HOST_PROTOCOL @"https"
#define HOST_PORT 8443
#define HOST_APP_CONTEXT @"moments-core"

#else

#define HOST_NAME @"localhost"
#define HOST_PROTOCOL @"http"
#define HOST_PORT 8081
#define HOST_APP_CONTEXT @"moments-core"

#endif

#define API_URL_BASE [NSString stringWithFormat:@"%@://%@:%d/%@", HOST_PROTOCOL, HOST_NAME, HOST_PORT, HOST_APP_CONTEXT]

#define DEFAULT_SESSION_TIMEOUT 15 * 60
#define DEFAULT_WS_REQUEST_TIMEOUT 10

#define ERROR_INVALID_ARG_KEY @"kErrorInvalidArgument"
#define ERROR_INVALID_ARG_FMT_KEY @"kErrorInvalidArgumentFmt"

#define NOTIFICATION_ACTION_PASS @"pass"
#define NOTIFICATION_ACTION_WATCH @"watch"
#define NOTIFICATION_CATEGORY_PASS_WATCH @"pass_watch"

#define VIDEO_INDEX_FILE_NAME @"index.m3u8"

#define VIDEO_PRESET_AUTO @"Auto"

#define STREAM_METADATA_FETCH_TIME 2

#define MINIMUM_BANDWITH_FOR_BROADCAST (40.0)

#define LIVE_STREAMS_CHANGE_INTERVAL 2

#define MAX_COUNT_OF_SAGMENT_FAILED_UPLOADS 3

UIKIT_EXTERN NSString * const MomentsErrorDomain;
UIKIT_EXTERN NSString * const MomentsErrorSeverityKey;


typedef enum _MomentsAuthType {
    kMomentsAuthTypeUnknown                = 0,
    kMomentsAuthTypeNative                 = 1,
    kMomentsAuthTypeFacebook               = 2
} MomentsAuthType;

typedef NS_ENUM(NSUInteger, ErrorCode) {
    
    kErrorCodeUnknown = -1,
    kErrorCodeInternalError = 0,
    kErrorCodeServerError = 1,
    kErrorCodeFBSignInCancelled = 2,
    kErrorCodeFBMissingFriendsPermission = 3,
    
};

typedef enum _ErrorSeverity {
    
    kErrorSeverityUnknown = 0,
    kErrorSeverityInfo = 1,
    kErrorSeverityWarning = 2,
    kErrorSeverityError = 3,
    
} ErrorSeverity;

typedef enum _Gender {
    
    kGenderUnknown = 0,
    kGenderMale = 1,
    kGenderFemale = 2
    
} Gender;

typedef NS_ENUM(NSUInteger, StreamState) {
    kStreamStateCreated = 0,
    kStreamStateReady = 1,
    kStreamStateStreaming = 2,
    kStreamStateClosed = 3
};

typedef NS_ENUM(NSUInteger, NotificationType) {
    kNotificationTypeBroadcastStarted = 0
};

typedef NS_ENUM(NSUInteger, DeviceType) {
    kDeviceTypeUnknown = 0,
    kDeviceTypeIOS = 1,
    DeviceTypeAndroid = 2
};

typedef NS_ENUM(NSUInteger, StreamEventType) {
    kStreamEventTypeUnknown = -1,
    kStreamEventTypeComment = 0,
    kStreamEventTypeLeave = 1,
    kStreamEventTypeJoin = 2,
    
};


#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

#define IS_OS_8_2_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.2)

#pragma mark - FB

#define FB_GENDER_MALE @"male"
#define FB_GENDER_FEMALE @"female"

#define THUMBNAIL_FILE_NAME @"thumb.jpg"
#define WIDE_THUMBNAIL_FILE_NAME @"wide_thumb.jpg"
#define THUMBNAIL_POSTER @"poster"
#define THUMBNAIL_WIDE @"wide"

#endif
