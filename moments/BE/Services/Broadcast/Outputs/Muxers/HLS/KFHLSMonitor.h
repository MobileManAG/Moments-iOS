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
//  KFHLSMonitor.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFHLSUploader.h"

@protocol KFHLSUploaderDelegate;
@class Stream;
@class KFHLSUploader;

@interface KFHLSMonitor : NSObject <KFHLSUploaderDelegate>

+ (KFHLSMonitor*) sharedMonitor;

- (void) startMonitoringFolderPath:(NSString*)path endpoint:(Stream*)endpoint delegate:(id<KFHLSUploaderDelegate>)delegate success:(void (^)(KFHLSUploader * uploader))success;
- (void) finishUploadingContentsAtFolderPath:(NSString*)path endpoint:(Stream*)endpoint; //reclaims delegate of uploader

@end
