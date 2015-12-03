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
//  KFHLSUploader.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/20/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFDirectoryWatcher.h"
#import "KFHLSManifestGenerator.h"
#import <AWSS3/AWSS3TransferManager.h>
#import <AWSS3/AWSS3.h>

@class Stream, KFHLSUploader, SegmentInfo;

@protocol KFHLSUploaderDelegate <NSObject>
@optional
- (void) uploader:(KFHLSUploader*)uploader didUploadSegmentAtURL:(NSURL*)segmentURL segment:(SegmentInfo *)segment numberOfQueuedSegments:(NSUInteger)numberOfQueuedSegments; //KBps
- (void) uploader:(KFHLSUploader*)uploader didDetectSegmentDrop:(SegmentInfo *)segment numberOfQueuedSegments:(NSUInteger)numberOfQueuedSegments;
- (void) uploader:(KFHLSUploader*)uploader didDetectSegmentDrops:(int)count numberOfQueuedSegments:(NSUInteger)numberOfQueuedSegments;
- (void) uploader:(KFHLSUploader *)uploader liveManifestReadyAtURL:(NSURL*)manifestURL;
- (void) uploader:(KFHLSUploader *)uploader vodManifestReadyAtURL:(NSURL*)manifestURL;
- (bool) uploader:(KFHLSUploader *)uploader thumbnailUploaded:(SegmentInfo *)thumbnailInfo;
- (bool) uploader:(KFHLSUploader *)uploader thumbnailUploadFailed:(SegmentInfo *)thumbnailInfo error:(NSError *)error;
- (void) uploaderHasFinished:(KFHLSUploader*)uploader;
@end

@interface KFHLSUploader : NSObject <KFDirectoryWatcherDelegate /*AmazonServiceRequestDelegate*/ >

@property (nonatomic, weak) id<KFHLSUploaderDelegate> delegate;
@property (readonly, nonatomic, strong) NSString *directoryPath;
@property (nonatomic) dispatch_queue_t scanningQueue;
@property (nonatomic) dispatch_queue_t callbackQueue;
@property (nonatomic, strong) Stream *stream;
@property (nonatomic) BOOL useSSL;
@property (nonatomic, strong) KFHLSManifestGenerator *manifestGenerator;
@property (nonatomic, assign) int countOfSegmentFailedUploads;
@property (atomic) bool isVideoUploadEnabled;

- (id) initWithDirectoryPath:(NSString*)directoryPath stream:(Stream*)stream;
- (void) finishedRecording;
- (void) uploadThumbnail:(NSString*)fileName thumbnailType:(NSString *)thumbnailType;

- (NSURL*) manifestURL;

@end
