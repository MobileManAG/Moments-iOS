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
//  Stream.h
//  moments
//
//  Created by MobileMan GmbH on 23.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import "mom_defines.h"


@class Location, User;

@interface Stream : MTLModel <MTLJSONSerializing, NSCoding>

@property (nonatomic, strong) NSString * uuid;
@property (nonatomic, assign) StreamState state;
@property (nonatomic, strong) NSString * text;

@property (nonatomic, strong) NSString * bucketName;
@property (nonatomic, strong) NSString * videoPathPrefix;
@property (nonatomic, strong) NSString * videoFileName;
@property (nonatomic, strong) NSString * videoBaseUrl;

@property (nonatomic, strong) NSString * thumbnailId;
@property (nonatomic, strong) NSString * thumbnailFileName;
@property (nonatomic, strong) NSString * thumbnailBaseUrl;
@property (nonatomic, strong) NSString * thumbnailPathPrefix;
@property (nonatomic, strong) User * user;
@property (nonatomic, strong) NSString * videoSharingUrl;
@property (nonatomic, strong) NSString * awsAccessKey;
@property (nonatomic, strong) NSString * awsSecretKey;

@property (nonatomic, strong) Location * location;

@end
