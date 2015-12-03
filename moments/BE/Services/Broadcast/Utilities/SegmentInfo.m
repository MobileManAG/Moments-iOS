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
//  SegmentInfo.m
//  moments
//
//  Created by MobileMan GmbH on 12.5.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <AWSS3/AWSS3.h>

#import "SegmentInfo.h"
#import "mom_defines.h"
#import "VideoUtils.h"



@interface SegmentInfo () {
    NSNumber * _segmentSize;
    NSNumber * _uploadSpeed;
    NSDate * _uploadStartDate;
    NSDate * _uploadFinishDate;

}

@end

static NSString * _directoryPath = nil;

@implementation SegmentInfo

+ (void)setDirectoryPath:(NSString *)directoryPath {
    _directoryPath = [directoryPath copy];
}

- (instancetype)initWithFileName:(NSString *)fileName index:(NSNumber *)index manifest:(NSString *)manifest {
    if (self = [super init]) {
        _uploadState = kUploadStateQueued;
        _fileName = [fileName copy];
        _manifest = [manifest copy];
        self.index = index;
    }
    
    return self;
}

+ (instancetype)create:(NSString *)fileName index:(NSNumber *)index manifest:(NSString *)manifest {
    SegmentInfo * result = [[SegmentInfo alloc] initWithFileName:fileName index:index manifest:manifest];
    return result;
}

-(NSString *)filePath {
    NSString *filePath = [_directoryPath stringByAppendingPathComponent:self.fileName];
    return filePath;
}

- (NSURL *)fileUrl {
    return [NSURL fileURLWithPath:self.filePath];
}

- (void)deleteFile {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:&error];
    if (error) {
        Log(@"Error removing uploaded segment: %@", error.description);
    }
}

- (void)uploadStarted {
    _uploadStartDate = [NSDate date];
    _uploadState = kUploadStateUploading;
}

- (void)uploadFinished {
    Log(@"Segment uploaded %@", self.fileName);
    _uploadFinishDate = [NSDate date];
    _uploadState = kUploadStateFinished;
    
    [self segmentSize];
    [self uploadSpeed];
    
    [self deleteFile];
}

- (void)uploadFailed {
    Log(@"Segment upload failed %@", self.fileName);
    [self.request cancel];
    self.request = nil;
    _uploadFinishDate = [NSDate date];
    _uploadState = kUploadStateFailed;
    [self deleteFile];
}

- (bool)isQueued {
    return [_uploadState isEqualToString:kUploadStateQueued];
}

- (bool)isUploading {
    return [_uploadState isEqualToString:kUploadStateUploading];
}

- (long long)segmentSize {
    if (_segmentSize) {
        return _segmentSize.longLongValue;
    }
    
    NSError *error = nil;
    NSDictionary *fileStats = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:&error];
    if (error) {
        Log(@"Error getting stats of path %@: %@", self.filePath, error);
    }
    uint64_t fileSize = [fileStats fileSize];
    _segmentSize = [NSNumber numberWithLongLong:fileSize];
    return _segmentSize.longLongValue;
}

- (double)uploadSpeed {
    if (_uploadSpeed) {
        return _uploadSpeed.doubleValue;
    }
    
    NSTimeInterval timeToUpload = [_uploadFinishDate timeIntervalSinceDate:_uploadStartDate];
    double bytesPerSecond = self.segmentSize / timeToUpload;
    double KBps = bytesPerSecond / 1024;
    _uploadSpeed = [NSNumber numberWithDouble:KBps];
    return _uploadSpeed.doubleValue;
}

- (double)uploadingTimeLength {
    NSTimeInterval timeToUpload = [[NSDate date] timeIntervalSinceDate:_uploadStartDate];
    return timeToUpload;
}

- (bool)timeToUploadExceeded {
    double utl = [self uploadingTimeLength];
    
    if (utl > [VideoUtils videoSegmentsDuration] * 2) {
        return true;
    }
    
    return false;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[%@ (%@)]", self.fileName, self.uploadState];
}

@end
