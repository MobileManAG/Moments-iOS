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
//  KFHLSUploader.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/20/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import <AWSS3/AWSS3.h>
#import "KFHLSUploader.h"
#import "MomAWSS3.h"
#import "Stream.h"
#import "VideoUtils.h"
#import "mom_defines.h"
#import "SegmentInfo.h"
#import "ThumbnailSegmentInfo.h"

@class AmazonServiceRequest, AmazonServiceResponse;

static NSString * const kManifestKey =  @"manifest";
static NSString * const kFileNameKey = @"fileName";
static NSString * const kFileStartDateKey = @"startDate";

static NSString * const kVODManifestFileName = @"vod.m3u8";


@interface KFHLSUploader()
@property (nonatomic) NSUInteger numbersOffset;
@property (nonatomic, strong) NSMutableDictionary *queuedSegments;
@property (nonatomic) NSUInteger nextSegmentIndexToUpload;
@property (nonatomic, strong) AWSS3TransferManager *transferManager;
@property (nonatomic, strong) AWSS3 * s3;
@property (nonatomic, strong) KFDirectoryWatcher *directoryWatcher;
@property (nonatomic, strong) NSString *manifestPath;
@property (nonatomic) BOOL manifestReady;
@property (nonatomic, strong) NSString *finalManifestString;
@property (nonatomic) BOOL isFinishedRecording;
@property (nonatomic) BOOL hasUploadedVODManifest;
@property (nonatomic) BOOL hasUploadedFinalManifest;
@property (nonatomic) SegmentInfo * posterUploadInfo;

@end

@implementation KFHLSUploader

- (id) initWithDirectoryPath:(NSString *)directoryPath stream:(Stream *)stream {
    if (self = [super init]) {
        self.stream = stream;
        _directoryPath = [directoryPath copy];
        [SegmentInfo setDirectoryPath:directoryPath];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.directoryWatcher = [KFDirectoryWatcher watchFolderWithPath:self.directoryPath delegate:self];
        });
        
        self.scanningQueue = dispatch_queue_create("KFHLSUploader Scanning Queue", DISPATCH_QUEUE_SERIAL);
        self.callbackQueue = dispatch_queue_create("KFHLSUploader Callback Queue", DISPATCH_QUEUE_SERIAL);
        self.queuedSegments = [NSMutableDictionary dictionaryWithCapacity:5];
        self.numbersOffset = 0;
        self.nextSegmentIndexToUpload = 0;
        self.manifestReady = NO;
        self.isFinishedRecording = NO;
        
        self.transferManager = [MomAWSS3 S3TransferManager:stream.awsAccessKey secretKey:stream.awsSecretKey];
        self.s3 = [MomAWSS3 S3:stream.awsAccessKey secretKey:stream.awsSecretKey];
        
        self.manifestGenerator = [[KFHLSManifestGenerator alloc] initWithTargetDuration:[VideoUtils videoSegmentsDuration] playlistType:KFHLSManifestPlaylistTypeLive];
    }
    return self;
}

- (NSString*) manifestSnapshot {
    NSString * manifest = [NSString stringWithContentsOfFile:_manifestPath encoding:NSUTF8StringEncoding error:nil];
    return manifest;
}

- (NSUInteger) indexForFilePrefix:(NSString*)filePrefix {
    NSString *numbers = [filePrefix substringFromIndex:_numbersOffset];
    return [numbers integerValue];
}

- (NSURL*) urlWithFileName:(NSString*)fileName {
    NSString *key = [self awsKeyForStreamVideo:self.stream fileName:fileName];
    NSString *ssl = @"";
    if (self.useSSL) {
        ssl = @"s";
    }
    NSString *urlString = [NSString stringWithFormat:@"http%@://%@.s3.amazonaws.com/%@", ssl, self.stream.bucketName, key];
    return [NSURL URLWithString:urlString];
}

- (NSURL*) manifestURL {
    NSString *manifestName = nil;
    if (self.isFinishedRecording) {
        manifestName = kVODManifestFileName;
    } else {
        manifestName = [_manifestPath lastPathComponent];
    }
    return [self urlWithFileName:manifestName];
}

- (void) finishedRecording {
    LogMethodStart;
    
    self.isFinishedRecording = YES;
    if (!self.hasUploadedVODManifest) {
        
        NSArray * indexes = [[self.queuedSegments allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 compare:obj2];
        }];
        for (NSNumber * segmentIndex in [indexes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF >= %d", _nextSegmentIndexToUpload]]) {
            [self.manifestGenerator addSegment:self.queuedSegments[segmentIndex]];
        }
        
        [self uploadVODManifest];
    }
    
    LogMethodEnd;
}

- (NSString*) awsKeyForStreamVideo:(Stream*)stream fileName:(NSString*)fileName {
    return [NSString stringWithFormat:@"%@/%@", stream.videoPathPrefix, fileName];
}

- (NSString*) awsKeyForStreamThumbnail:(Stream*)stream thumbnailType:(NSString *)thumbnailType {
    
    if ([stream.thumbnailPathPrefix hasPrefix:@"/"]) {
        stream.thumbnailPathPrefix = [stream.thumbnailPathPrefix substringFromIndex:1];
    }
    
    return [NSString stringWithFormat:@"%@/%@_%@", stream.thumbnailPathPrefix, thumbnailType, stream.thumbnailFileName];
}

- (void)uploadVODManifest {
    [self.manifestGenerator finalizeManifest];
    NSString *manifestString = [self.manifestGenerator manifestString];
    [self updateManifestWithString:manifestString manifestName:kVODManifestFileName];
}

- (void) uploadNextSegment {
    LogMethodStart;
    
    
    if (self.isVideoUploadEnabled == false) {
        Log(@"Video upload not yest enabled");
        LogMethodStart;
        return;
    }
    
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.directoryPath error:nil];
    NSUInteger tsFileCount = 0;
    for (NSString *fileName in contents) {
        if ([[fileName pathExtension] isEqualToString:@"ts"]) {
            tsFileCount++;
        }
    }
    
    __block SegmentInfo * segment = [_queuedSegments objectForKey:@(_nextSegmentIndexToUpload)];
    if (segment == nil) {
        Log(@"Queue is empty: segment = %d", _nextSegmentIndexToUpload);
        
        if (self.isFinishedRecording) {
            [self finishInternal];
        }
        
        LogMethodEnd;
        return;
    }
    
    // Skip uploading files that are currently being written
    if (tsFileCount == 1 && !self.isFinishedRecording) {
        Log(@"Skipping upload of ts file currently being recorded: %@ %@", segment, contents);
        return;
    }
    
    if (!segment.isQueued) {
        Log(@"Trying to upload file that isn't queued %@", segment);
        
        /*
        if ([segment timeToUploadExceeded]) {
            [segment.request cancel];
        }
        */
        if (self.isFinishedRecording) {
            [self finishInternal];
        }
        
        LogMethodEnd;
        return;
    }
    
    [segment uploadStarted];
    
    NSString *key = [self awsKeyForStreamVideo:self.stream fileName:segment.fileName];
    
    AWSS3TransferManagerUploadRequest *request = [AWSS3TransferManagerUploadRequest new];
    request.bucket = self.stream.bucketName;
    request.key = key;
    request.ACL = AWSS3ObjectCannedACLPublicRead;
    request.storageClass = AWSS3StorageClassReducedRedundancy;
    request.contentType = @"video/MP2T";
    request.cacheControl = @"max-age=0";
    request.contentLength = [NSNumber numberWithUnsignedLongLong:segment.segmentSize];
    request.body = segment.fileUrl;
    segment.request = request;
    
    [[self.transferManager upload:request] continueWithBlock:^id(BFTask *task) {
        
        dispatch_async(_scanningQueue, ^{
            
            segment.request = nil;
            
            if (task.error) {
                ++self.countOfSegmentFailedUploads;
                [segment uploadFailed];
                [self.manifestGenerator addFailedSegment:segment];
                [_queuedSegments removeObjectForKey:@(_nextSegmentIndexToUpload)];
                _nextSegmentIndexToUpload++;
                NSUInteger queuedSegmentsCount = _queuedSegments.count;
                
                LogError(@"Failed to upload request, uploading next segment %@: %@", segment.fileName, task.error.description);
                
                if ([self.delegate respondsToSelector:@selector(uploader:didDetectSegmentDrop:numberOfQueuedSegments:)]) {
                    [self.delegate uploader:self didDetectSegmentDrop:segment numberOfQueuedSegments:queuedSegmentsCount];
                }
                
                if (self.countOfSegmentFailedUploads >= MAX_COUNT_OF_SAGMENT_FAILED_UPLOADS) {
                    int count = self.countOfSegmentFailedUploads;
                    self.countOfSegmentFailedUploads = 0;
                    if ([self.delegate respondsToSelector:@selector(uploader:didDetectSegmentDrop:numberOfQueuedSegments:)]) {
                        [self.delegate uploader:self didDetectSegmentDrops:count numberOfQueuedSegments:queuedSegmentsCount];
                    }
                    
                }
                
                [self uploadNextSegment];
                LogMethodEnd;
                return;
            }
            
            self.countOfSegmentFailedUploads = 0;
            [segment uploadFinished];
            
            [_queuedSegments removeObjectForKey:@(_nextSegmentIndexToUpload)];
            
            NSUInteger queuedSegmentsCount = _queuedSegments.count;
            
            //
            if (self.isFinishedRecording) {
                if (!self.hasUploadedVODManifest) {
                    [self uploadVODManifest];
                }
            }
            
            [self.manifestGenerator addSegment:segment];
            [self updateManifestWithString:segment.manifest manifestName:VIDEO_INDEX_FILE_NAME];
            
            _nextSegmentIndexToUpload++;
            [self uploadNextSegment];
            
            if ([self.delegate respondsToSelector:@selector(uploader:didUploadSegmentAtURL:segment:numberOfQueuedSegments:)]) {
                
                NSURL *url = [self urlWithFileName:segment.fileName];
                dispatch_async(self.callbackQueue, ^{
                    [self.delegate uploader:self didUploadSegmentAtURL:url segment:segment numberOfQueuedSegments:queuedSegmentsCount];
                });
            }
            
            LogMethodEnd;
        });
        
        return nil;
    }];
}

- (void) uploadThumbnail:(NSString*)fileName thumbnailType:(NSString *)thumbnailType {
    LogMethodStart;
    
    if (self.posterUploadInfo) {
        Log(@"Poster upload state: %@", self.posterUploadInfo.uploadState);
        LogMethodEnd;
    }
    
    NSString *key = [self awsKeyForStreamThumbnail:self.stream thumbnailType:thumbnailType];
    NSString * url = [NSString stringWithFormat:@"%@/%@_%@", self.stream.thumbnailBaseUrl, thumbnailType, self.stream.thumbnailFileName];
    
    self.posterUploadInfo = [ThumbnailSegmentInfo create:fileName thumbnailType:thumbnailType url:url];
    
    AWSS3TransferManagerUploadRequest *request = [AWSS3TransferManagerUploadRequest new];
    request.bucket = self.stream.bucketName;
    request.key = key;
    request.body = self.posterUploadInfo.fileUrl;
    request.ACL = AWSS3ObjectCannedACLPublicRead;
    request.storageClass = AWSS3StorageClassReducedRedundancy;
    request.cacheControl = @"max-age=0";
    request.contentType = @"image/jpg";
    request.contentLength = @(self.posterUploadInfo.segmentSize);
    [self.posterUploadInfo uploadStarted];
    
    [[self.transferManager upload:request] continueWithBlock:^id(BFTask *task) {
        dispatch_async(_scanningQueue, ^{
            
            if (task.error) {
                [self.posterUploadInfo uploadFailed];
                LogError(@"Failed to upload request, requeuing %@: %@", self.posterUploadInfo, task.error.description);
                
                self.isVideoUploadEnabled = [self.delegate uploader:self thumbnailUploadFailed:self.posterUploadInfo error:task.error];
                self.posterUploadInfo = nil;
                [self uploadNextSegment];
                
                LogMethodEnd;
                return;
            }
            
            [self.posterUploadInfo uploadFinished];            
            
            SegmentInfo * oldSegment = self.posterUploadInfo;
            self.posterUploadInfo = nil;
            if ([self.delegate respondsToSelector:@selector(uploader:thumbnailUploaded:)]) {
                dispatch_async(self.callbackQueue, ^{
                    self.isVideoUploadEnabled = [self.delegate uploader:self thumbnailUploaded:oldSegment];
                });
            }
            
            [self uploadNextSegment];
            LogMethodEnd;
        });
        
        return nil;
    }];
    
}

- (void) updateManifestWithString:(NSString*)manifestString manifestName:(NSString*)manifestName {
    LogMethodStart;
    
    NSData *data = [manifestString dataUsingEncoding:NSUTF8StringEncoding];
    //NSLog(@"New manifest:\n%@", manifestString);
    NSString *key = [self awsKeyForStreamVideo:self.stream fileName:manifestName];
    
    AWSS3PutObjectRequest *request = [AWSS3PutObjectRequest new];
    request.bucket = self.stream.bucketName;
    request.key = key;
    request.body = data;
    request.ACL = AWSS3ObjectCannedACLPublicRead;
    request.contentLength = [NSNumber numberWithLong:data.length];
    request.storageClass = AWSS3StorageClassReducedRedundancy;
    request.cacheControl = @"max-age=0";
    request.contentType = @"application/x-mpegURL";
    
    [[self.s3 putObject:request] continueWithBlock:^id(BFTask *task) {
        
        dispatch_async(_scanningQueue, ^{
            
            if (task.error) {
                Log(@"Failed to upload request, requeuing %@: %@", manifestName, task.error.description);
                
                if (self.isFinishedRecording) {
                    [self finishInternal];
                } else {
                    [self uploadNextSegment];
                }
                
                LogMethodEnd;
                return;
            }
            
            if ([manifestName isEqualToString:kVODManifestFileName]) {
                self.hasUploadedVODManifest = YES;
            }
            
            if (!_manifestReady) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(uploader:liveManifestReadyAtURL:)]) {
                    [self.delegate uploader:self liveManifestReadyAtURL:[self manifestURL]];
                }
                _manifestReady = YES;
            }
            
            Log(@"isFinishedRecording = %d, queuedSegments.count = %lu", self.isFinishedRecording, (unsigned long)_queuedSegments.count);
            
            if (self.isFinishedRecording) {
                [self finishInternal];
            }
            
            LogMethodEnd;
        });
        
        return nil;
    }];
}

- (void)finishInternal {
    if (!self.isFinishedRecording) {
        return;
    }
    
    SegmentInfo *segment = [_queuedSegments objectForKey:@(_nextSegmentIndexToUpload)];
    // finished and empty queue or next file not uploading
    if (_queuedSegments.count == 0 || !segment.isUploading) {
        
        if (!self.hasUploadedFinalManifest) {
            self.hasUploadedFinalManifest = YES;
            NSString * manifest = [self manifestSnapshot];
            [self updateManifestWithString:manifest manifestName:VIDEO_INDEX_FILE_NAME];
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploader:vodManifestReadyAtURL:)]) {
                [self.delegate uploader:self vodManifestReadyAtURL:[self manifestURL]];
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploaderHasFinished:)]) {
                [self.delegate uploaderHasFinished:self];
            }
        }
    }
    
}

- (void) directoryDidChange:(KFDirectoryWatcher *)folderWatcher {
    dispatch_async(_scanningQueue, ^{
        NSError *error = nil;
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.directoryPath error:&error];
        NSLog(@"Directory changed, fileCount: %d", files.count);
        if (error) {
            NSLog(@"Error listing directory contents: %@", error);
        }
        
        if (!_manifestPath) {
            [self initializeManifestPathFromFiles:files];
        }
        
        [self detectNewSegmentsFromFiles:files];
    });
}

- (void) detectNewSegmentsFromFiles:(NSArray*)files {
    LogMethodStart;
    
    if (self.isVideoUploadEnabled == false) {
        Log(@"Poster uplad not yet started");
        LogMethodEnd;
        return;
    }
    
    if (!_manifestPath) {
        Log(@"Manifest path not yet available");
        LogMethodEnd;
        return;
    }

    [files enumerateObjectsUsingBlock:^(NSString *fileName, NSUInteger idx, BOOL *stop) {
        NSArray *components = [fileName componentsSeparatedByString:@"."];
        NSString *filePrefix = [components firstObject];
        NSString *fileExtension = [components lastObject];
        
        if ([fileExtension isEqualToString:@"ts"]) {
            NSUInteger segmentIndex = [self indexForFilePrefix:filePrefix];
            SegmentInfo * segment = _queuedSegments[@(segmentIndex)];
            if (segment == nil) {
                Log(@"New ts file detected: %@", fileName);
                segment = [SegmentInfo create:fileName index:@(segmentIndex) manifest:[self manifestSnapshot]];
                [_queuedSegments setObject:segment forKey:segment.index];
                
                [self uploadNextSegment];
            } else {
                if ([segment isQueued] && [segment timeToUploadExceeded]) {
                    [segment uploadFailed];
                }
            }
        }
    }];
    
    LogMethodEnd;
}

- (void) initializeManifestPathFromFiles:(NSArray*)files {
    [files enumerateObjectsUsingBlock:^(NSString *fileName, NSUInteger idx, BOOL *stop) {
        if ([[fileName pathExtension] isEqualToString:@"m3u8"]) {
            NSArray *components = [fileName componentsSeparatedByString:@"."];
            NSString *filePrefix = [components firstObject];
            _manifestPath = [_directoryPath stringByAppendingPathComponent:fileName];
            _numbersOffset = filePrefix.length;
            NSAssert(_numbersOffset > 0, nil);
            *stop = YES;
        }
    }];
}

@end
