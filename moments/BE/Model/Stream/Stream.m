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
//  Stream.m
//  moments
//
//  Created by MobileMan GmbH on 23.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "Stream.h"

@implementation Stream


+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             NSStringFromSelector(@selector(uuid)): @"id",
             NSStringFromSelector(@selector(text)): @"text",
             NSStringFromSelector(@selector(location)): @"location",
             NSStringFromSelector(@selector(bucketName)): @"bucketName",
             NSStringFromSelector(@selector(videoPathPrefix)): @"pathPrefix",
             NSStringFromSelector(@selector(location)): @"location",
             NSStringFromSelector(@selector(videoBaseUrl)): @"baseUrl",
             NSStringFromSelector(@selector(videoFileName)): @"videoFileName",
             NSStringFromSelector(@selector(videoSharingUrl)): @"sharingUrl",
             NSStringFromSelector(@selector(thumbnailId)): @"thumbnailId",
             NSStringFromSelector(@selector(thumbnailFileName)): @"thumbnailFileName",
             NSStringFromSelector(@selector(thumbnailBaseUrl)): @"thumbnailBaseUrl",
             NSStringFromSelector(@selector(awsAccessKey)): @"scak",
             NSStringFromSelector(@selector(awsSecretKey)): @"scsk",

             };
}

@end
