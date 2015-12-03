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
//  KFHLSMonitor.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFHLSMonitor.h"
#import "KFHLSUploader.h"
#import "Stream.h"

@interface KFHLSMonitor()
@property (nonatomic, strong) NSMutableDictionary *hlsUploaders;
@property (nonatomic) dispatch_queue_t monitorQueue;
@end

static KFHLSMonitor *_sharedMonitor = nil;

@implementation KFHLSMonitor

+ (KFHLSMonitor*) sharedMonitor {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedMonitor = [[KFHLSMonitor alloc] init];
    });
    return _sharedMonitor;
}

- (id) init {
    if (self = [super init]) {
        self.hlsUploaders = [NSMutableDictionary dictionary];
        self.monitorQueue = dispatch_queue_create("HLS Monitor Queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void) startMonitoringFolderPath:(NSString *)path endpoint:(Stream *)stream delegate:(id<KFHLSUploaderDelegate>)delegate success:(void (^)(KFHLSUploader * uploader))success {
    dispatch_sync(self.monitorQueue, ^{
        KFHLSUploader *hlsUploader = [[KFHLSUploader alloc] initWithDirectoryPath:path stream:stream];
        hlsUploader.delegate = delegate;
        [self.hlsUploaders setObject:hlsUploader forKey:path];
        if (success) {
            success(hlsUploader);
        }
    });
}

- (void) finishUploadingContentsAtFolderPath:(NSString*)path endpoint:(Stream*)endpoint {
    if (path.length == 0 || endpoint == nil) {
        return;
    }
    
    dispatch_async(self.monitorQueue, ^{
        KFHLSUploader *hlsUploader = [self.hlsUploaders objectForKey:path];
        if (!hlsUploader) {
            hlsUploader = [[KFHLSUploader alloc] initWithDirectoryPath:path stream:endpoint];
            [self.hlsUploaders setObject:hlsUploader forKey:path];
        }

        [hlsUploader finishedRecording];
    });
}

- (void) uploaderHasFinished:(KFHLSUploader*)uploader {
    dispatch_async(self.monitorQueue, ^{
        [self.hlsUploaders removeObjectForKey:uploader.directoryPath];
    });
}

@end
