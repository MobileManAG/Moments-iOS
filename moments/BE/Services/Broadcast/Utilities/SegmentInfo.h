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
//  SegmentInfo.h
//  moments
//
//  Created by MobileMan GmbH on 12.5.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const kUploadStateQueued = @"queued";
static NSString * const kUploadStateFinished = @"finished";
static NSString * const kUploadStateUploading = @"uploading";
static NSString * const kUploadStateFailed = @"failed";

@class AWSS3PutObjectRequest;

@interface SegmentInfo : NSObject

@property (nonatomic, readonly) NSString * fileName;
@property (nonatomic, readonly) NSString * filePath;
@property (nonatomic, readonly) NSURL * fileUrl;
@property (nonatomic, readonly) NSString * uploadState;
@property (nonatomic, assign, readonly) long long segmentSize;
@property (nonatomic, assign, readonly) double uploadSpeed;
@property (nonatomic, readonly) NSString * manifest;
@property (nonatomic, assign, readonly) double uploadingTimeLength;
@property (nonatomic, strong) AWSS3PutObjectRequest * request;
@property (nonatomic, strong) NSNumber * index;
@property NSString * url;
@property (nonatomic, assign, getter=isLastSegment) bool lastSegment;


+ (void)setDirectoryPath:(NSString *)directoryPath;
+ (instancetype)create:(NSString *)fileName index:(NSNumber *)index manifest:(NSString *)manifest;
- (instancetype)initWithFileName:(NSString *)fileName index:(NSNumber *)index manifest:(NSString *)manifest;
- (void)uploadStarted;
- (void)uploadFinished;
- (void)uploadFailed;
- (bool)isQueued;
- (bool)isUploading;
- (bool)timeToUploadExceeded;

@end
