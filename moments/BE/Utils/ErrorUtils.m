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
//  ErrorUtils.m
//  moments
//
//  Created by MobileMan GmbH on 21.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "ErrorUtils.h"
#import "mom_defines.h"
#import "mom_notifications.h"
#import "AFURLResponseSerialization.h"

NSString * const MomentsErrorDomain = @"com.mobileman.moments";
NSString * const MomentsErrorSeverityKey = @"MomentsErrorSeverityKey";

@implementation ErrorUtils

+ (NSError *)createWrongParameterError {
    return [self createError:NSLocalizedString(ERROR_INVALID_ARG_KEY, ERROR_INVALID_ARG_KEY) code:kErrorCodeInternalError];
}

+ (NSError *)createWrongParameterError:(NSString *)parameterName {
    return [self createError:[NSString stringWithFormat:NSLocalizedString(ERROR_INVALID_ARG_FMT_KEY, ERROR_INVALID_ARG_FMT_KEY), parameterName] code:kErrorCodeInternalError];
}

+ (NSError *)createError:(NSString *)message code:(NSInteger)code {
    return [self createError:message code:code severity:kErrorSeverityError];
}

+ (NSError *)createError:(NSString *)message code:(NSInteger)code severity:(ErrorSeverity)severity {
    return [NSError errorWithDomain:MomentsErrorDomain code:code userInfo:@{
                                                                         NSLocalizedDescriptionKey: message == nil ? @"" : message,
                                                                         MomentsErrorSeverityKey : @(severity)
                                                                         }];
}

+ (NSError *)createError:(NSString *)message code:(NSInteger)code severity:(ErrorSeverity)severity reason:(NSString *)reason {
    return [NSError errorWithDomain:MomentsErrorDomain code:code userInfo:@{
                                                                         NSLocalizedDescriptionKey: message == nil ? @"" : message,
                                                                         NSLocalizedFailureReasonErrorKey : reason == nil ? @"" : reason,
                                                                         MomentsErrorSeverityKey : @(severity)
                                                                         }];
}

+ (NSError *)createMissingSessionError {
    return [ErrorUtils createError:@"User session missing" code:kErrorCodeInternalError];
}

+ (NSUInteger)httpStatusCode:(NSError *)error {
    NSUInteger code = 200;
    NSURLResponse * response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
    if ([response isKindOfClass:NSHTTPURLResponse.class]) {
        NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
        code = httpResponse.statusCode;
    }
    
    return code;
}

+ (void)handleUnauthorizedRequestError:(NSError *)error {
    NSUInteger statusCode = [self httpStatusCode:error];
    
    if (statusCode == 401) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MOMSessionExpiredNotification object:nil userInfo:@{@"error":error}];
    }
}

@end
