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
//  BroadcastServiceImpl.m
//  moments
//
//  Created by MobileMan GmbH on 15.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

@import CoreLocation;
@import CoreTelephony;

#import "BroadcastServiceImpl.h"
#import <UIKit/UIApplication.h>
#import "ServiceFactory.h"
#import "User.h"
#import "Stream.h"
#import "Location.h"
#import "Settings.h"
#import "UserUtils.h"
#import "ErrorUtils.h"
#import "UserSession.h"
#import "KFH264Encoder.h"
#import "KFAACEncoder.h"
#import "KFHLSWriter.h"
#import "KFHLSMonitor.h"
#import "KFVideoFrame.h"
#import "VideoUtils.h"
#import "FileUtils.h"
#import "SegmentInfo.h"
#import <Reachability/Reachability.h>
#import "WSBindingImpl.h"

#define POSTER_QUALITY 0.9

@interface BroadcastServiceImpl () <KFEncoderDelegate, CLLocationManagerDelegate>
@property (nonatomic) BOOL hasScreenshot;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation * lastLocation;
@property (strong) KFHLSUploader * hlsUploader;
@property (nonatomic, strong) UIImage * thumbnail;
@property (nonatomic, strong) CTTelephonyNetworkInfo *telephonyNetworkInfo;
@property (nonatomic, strong) Reachability * reachabilityForInternetConnection;

@end

@implementation BroadcastServiceImpl

@synthesize broadcasting;
@synthesize session;
@synthesize delegate;

-(id)init {
    if (self = [super init]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.telephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
        self.reachabilityForInternetConnection = [Reachability reachabilityForInternetConnection];
        __weak BroadcastServiceImpl * weekSelf = self;
        
        self.reachabilityForInternetConnection.unreachableBlock = ^(Reachability * reachability){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Internet Connection UnReachable");
                [weekSelf updateVideoSession];
            });
        };
        
        self.reachabilityForInternetConnection.reachableBlock = ^(Reachability * reachability){
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Internet Connection Reachable");
                [weekSelf updateVideoSession];
            });
        };
        
        [self.reachabilityForInternetConnection startNotifier];
        
        self.telephonyNetworkInfo.subscriberCellularProviderDidUpdateNotifier = ^(CTCarrier* carier){
            [weekSelf updateVideoSession];
        };
        
        [self setupSession];
        //[self setupEncoders];
        self.wsBinding = [WSBindingImpl instance];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationDidEnterBackground:)
                                                     name: UIApplicationDidEnterBackgroundNotification
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillResignActive:)
                                                     name: UIApplicationWillResignActiveNotification
                                                   object: nil];
        
        
        
    }
    
    return self;
}

-(id)initWithDelegate:(id<BroadcastServiceDelegate>)_delegate {
    if (self = [self init]) {
        self.delegate = _delegate;
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self teardownCaptureSession];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self stopBroadcasting];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    [self stopBroadcasting];
}

- (void)setupSession {
    _audioQueue = dispatch_queue_create("com.mobileman.moments.audio.capture.queue", DISPATCH_QUEUE_SERIAL);
    _videoQueue = dispatch_queue_create("com.mobileman.moments.video.capture.queue", DISPATCH_QUEUE_SERIAL);
    _sessionQueue = dispatch_queue_create("com.mobileman.moments.session.queue", DISPATCH_QUEUE_SERIAL);
    self.session = [[AVCaptureSession alloc] init];
    [self setupVideoDevice:AVCaptureDevicePositionBack];
    [self setupAudioDevice];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionNotification:) name:nil object:self.session];
    
    self.applicationWillEnterForegroundNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication] queue:nil usingBlock:^(NSNotification *note) {
        [self applicationWillEnterForeground];
    }];
}

- (void)updateVideoSession {
    NSString * currentRadioAccessTechnology = self.telephonyNetworkInfo.currentRadioAccessTechnology;
    NetworkStatus networkStatus = self.reachabilityForInternetConnection.currentReachabilityStatus;
    NSString * videoSessionPreset = [VideoUtils videoSessionPreset:networkStatus mobileNetworkType:currentRadioAccessTechnology];
    [self setVideoSessionPreset:videoSessionPreset failure:^(NSError *error) {
        LogError(@"Error while updating video session: %@", error);
    }];
}

- (void) setupEncoders {
    
    self.audioSampleRate = [VideoUtils audioSamplerate];
    self.videoHeight = [self.recommendedVideoSettings[AVVideoHeightKey] intValue];
    self.videoWidth = [self.recommendedVideoSettings[AVVideoWidthKey] intValue];
    if (self.videoHeight < self.videoWidth) {
        int tmpHeight = self.videoHeight;
        self.videoHeight = self.videoWidth;
        self.videoWidth = tmpHeight;
    }
    
    int audioBitrate = [VideoUtils audioBitrate]; // 64 Kbps
    int videoBitrate = [VideoUtils minBitrate] - audioBitrate;
    _h264Encoder = [[KFH264Encoder alloc] initWithBitrate:videoBitrate width:self.videoWidth height:self.videoHeight];
    _h264Encoder.delegate = self;
    
    _aacEncoder = [[KFAACEncoder alloc] initWithBitrate:audioBitrate sampleRate:self.audioSampleRate channels:1];
    _aacEncoder.delegate = self;
    _aacEncoder.addADTSHeader = YES;
}

- (void) setupHLSWriterWithEndpoint:(Stream*)endpoint {
    LogMethodStart;
    
    NSString *folderName = [NSString stringWithFormat:@"%@.hls", endpoint.uuid];
    NSString *hlsDirectoryPath = [[FileUtils streamsDirectory] stringByAppendingPathComponent:folderName];
    [[NSFileManager defaultManager] createDirectoryAtPath:hlsDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    self.hlsWriter = [[KFHLSWriter alloc] initWithDirectoryPath:hlsDirectoryPath];
    [self.hlsWriter addVideoStreamWithWidth:self.videoWidth height:self.videoHeight];
    [self.hlsWriter addAudioStreamWithSampleRate:self.audioSampleRate];
    
    [[KFHLSMonitor sharedMonitor] startMonitoringFolderPath:_hlsWriter.directoryPath endpoint:self.stream delegate:self success:^(KFHLSUploader *uploader) {
        self.hlsUploader = uploader;
    }];
    
    LogMethodEnd;

}

- (AVCaptureDevice *)audioDevice {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    return [devices firstObject];
}

- (AVCaptureDevice *)videoDevice:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) return device;
    }
    
    return [devices firstObject];
}

- (void) setupAudioDevice {
    NSError *error = nil;
    AVCaptureDevice *audioDevice = [self audioDevice];
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"setupAudioDevice error: %@", error.description);
        return;
    }
    if ([self.session canAddInput:audioInput]) {
        [self.session addInput:audioInput];
    }
    
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioOutput setSampleBufferDelegate:self queue:_audioQueue];
    if ([self.session canAddOutput:_audioOutput]) {
        [self.session addOutput:_audioOutput];
    }
    _audioConnection = [_audioOutput connectionWithMediaType:AVMediaTypeAudio];
}

- (void) setupVideoDevice:(AVCaptureDevicePosition)position {
    NSError *error = nil;
    
    AVCaptureDevice* videoDevice = [self videoDevice:position];
    if (videoDevice == nil) {
        return;
    }
    
    if ( [videoDevice lockForConfiguration:&error] ) {
        int frameRate = [VideoUtils videoFrameRate];
        CMTime frameDuration = CMTimeMake( 1, frameRate );
        videoDevice.activeVideoMaxFrameDuration = frameDuration;
        videoDevice.activeVideoMinFrameDuration = frameDuration;
        [videoDevice unlockForConfiguration];
    }
    else {
        NSLog( @"videoDevice lockForConfiguration returned error %@", error );
        return;
    }
    
    AVCaptureDeviceInput * videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (error) {
        NSLog(@"setupVideoDevice error: %@", error.description);
        return;
    }
    
    [self.session beginConfiguration];
    
    if (self.videoInput) {
        [self.session removeInput:self.videoInput];
    }
    
    self.videoInput = videoInput;
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    NSString * mobileNetworkType = self.telephonyNetworkInfo.currentRadioAccessTechnology;
    NetworkStatus networkStatus = self.reachabilityForInternetConnection.currentReachabilityStatus;
    NSString *sessionPreset = [VideoUtils videoSessionPreset:networkStatus mobileNetworkType:mobileNetworkType];
    if ( [self.session canSetSessionPreset:sessionPreset] ) {
        self.session.sessionPreset = sessionPreset;
    }
    
    AVCaptureVideoDataOutput * videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    NSDictionary *captureSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    videoOutput.videoSettings = captureSettings;
    videoOutput.alwaysDiscardsLateVideoFrames = YES;
    if (self.videoOutput) {
        [self.session removeOutput:self.videoOutput];
    }
    
    self.videoOutput = videoOutput;
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
    }
    
    self.videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    [self.session commitConfiguration];
    
    self.recommendedVideoSettings = [videoOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie];
    
}


- (void)applicationWillEnterForeground {
    NSLog( @"-[%@ %@] called", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
    /*
    dispatch_sync( _sessionQueue, ^{
        if ( _startCaptureSessionOnEnteringForeground ) {
            NSLog( @"-[%@ %@] manually restarting session", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
            
            _startCaptureSessionOnEnteringForeground = NO;
            if ( _running ) {
                [_captureSession startRunning];
            }
        }
    } );
    */
}

- (void)captureSessionNotification:(NSNotification *)notification
{
    NSString * notificationName = notification.name;
    NSLog( @"captureSessionNotification: %@", notificationName);
    dispatch_async( _sessionQueue, ^{
        
        if ( [notificationName isEqualToString:AVCaptureSessionWasInterruptedNotification] )
        {
            NSLog( @"session interrupted" );
            
            //[self captureSessionDidStopRunning];
        }
        else if ( [notificationName isEqualToString:AVCaptureSessionInterruptionEndedNotification] )
        {
            NSLog( @"session interruption ended" );
        }
        else if ( [notificationName isEqualToString:AVCaptureSessionRuntimeErrorNotification] )
        {
            //[self captureSessionDidStopRunning];
            
            NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
            if ( error.code == AVErrorDeviceIsNotAvailableInBackground )
            {
                NSLog( @"device not available in background" );
                
                // Since we can't resume running while in the background we need to remember this for next time we come to the foreground
                if ( self.isBroadcasting ) {
                    NSLog( @"_startCaptureSessionOnEnteringForeground = YES" );
                    //_startCaptureSessionOnEnteringForeground = YES;
                }
            }
            else if ( error.code == AVErrorMediaServicesWereReset )
            {
                NSLog( @"media services were reset" );
                [self handleRecoverableCaptureSessionRuntimeError:error];
            }
            else
            {
                [self handleNonRecoverableCaptureSessionRuntimeError:error];
            }
        }
        else if ( [notificationName isEqualToString:AVCaptureSessionDidStartRunningNotification] )
        {
            NSLog( @"session started running" );
        }
        else if ( [notificationName isEqualToString:AVCaptureSessionDidStopRunningNotification] )
        {
            NSLog( @"session stopped running" );
        }
    } );
}

- (void)handleRecoverableCaptureSessionRuntimeError:(NSError *)error
{
    if ( self.isBroadcasting ) {
        [self.session startRunning];
    }
}

- (void)handleNonRecoverableCaptureSessionRuntimeError:(NSError *)error {
    NSLog( @"fatal runtime error %@, code %i", error, (int)error.code );
    
    self.broadcasting = false;
    [self teardownCaptureSession];
    
    [self.delegate broadcastService:self didStopRunningWithError:error];
}


- (void)teardownCaptureSession {
    
}

// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

#pragma mark - Interface methods

- (void)startBroadcasting:(NSString *)text location:(CLLocation *)location {
    LogMethodStart;
    
    UserSession * userSession = [Settings currentSession];
    if (!userSession) {
        [self.delegate broadcastService:self didStopBroadcastingWithError:[ErrorUtils createMissingSessionError]];
        LogMethodEnd;
        return;
    }
    
    if (IS_OS_8_OR_LATER) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    self.hasScreenshot = NO;
    [self.locationManager startUpdatingLocation];
    [self setVideoSessionPreset:[VideoUtils videoSessionPreset] failure:nil];
    
    [self setupEncoders];
    if (text.length == 0) {
        //text = [NSString stringWithFormat:NSLocalizedString(@"kLabelDefaultNotificationTitleFmt", @"kLabelDefaultNotificationTitleFmt"), [UserUtils userName:userSession.user]];
        text = @"";
    }
        
    [self.wsBinding startBroadcast:text location:location videoFileName:VIDEO_INDEX_FILE_NAME thumbnailFileName:THUMBNAIL_FILE_NAME stream:^(Stream *stream) {
        self.stream = stream;
        self.stream.user = userSession.user;
        self.broadcasting = true;
        
        [self setupHLSWriterWithEndpoint:self.stream];
        
        NSError *error = nil;
        [self.hlsWriter prepareForWriting:&error];
        if (error) {
            NSLog(@"Error preparing for writing: %@", error);
            [self.delegate broadcastService:self didStopBroadcastingWithError:error];
            LogMethodEnd;
            return;
        }
        
        [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate broadcastServiceDidStartBroadcasting:self stream:stream];
        });
        
        LogMethodEnd;
        
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate broadcastService:self didStopBroadcastingWithError:error];
        });
        
        LogMethodEnd;
    }];
}

- (void)stopBroadcasting {
    LogMethodStart
    
    if (!self.isBroadcasting) {
        LogMethodEnd
        return;
    }

    self.broadcasting = false;
    [self.locationManager stopUpdatingLocation];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self.wsBinding stopBroadcast:self.stream success:^(Stream *stream) {
            Log(@"Stream stopped: %@", self.stream.uuid);
        } failure:^(NSError *error) {
            LogError(@"Error stopping stream: %@", error);
        }];
        
        NSError *error = nil;
        [self.hlsWriter finishWriting:&error];
        if (error) {
            LogError(@"Error stop recording: %@", error);
        }
        
        [[KFHLSMonitor sharedMonitor] finishUploadingContentsAtFolderPath:self.hlsWriter.directoryPath endpoint:self.stream];
        LogMethodEnd
    });
}

- (void)switchCameraWithPosition:(AVCaptureDevicePosition)position {
    if(self.videoInput.device.position != position) {
        [self setupVideoDevice:position];
    }
}

- (void)switchCamera:(void (^)(NSError *error))failure {
    
    if(self.videoInput.device.position == AVCaptureDevicePositionBack) {
        [self setupVideoDevice:AVCaptureDevicePositionFront];
    }
    else {
        [self setupVideoDevice:AVCaptureDevicePositionBack];
    }
}

- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) return device;
    }
    
    return nil;
}

- (void)setVideoSessionPreset:(NSString *)videoSessionPreset failure:(void (^)(NSError *error))failure {
    if ( [self.session canSetSessionPreset:videoSessionPreset] ) {
        self.session.sessionPreset = videoSessionPreset;
    } else {
        if (failure) {
            failure([ErrorUtils createError:@"Desired preset can not be set" code:kErrorCodeInternalError]);
        }
    }
}

#pragma mark KFEncoderDelegate method
- (void) encoder:(KFEncoder*)encoder encodedFrame:(KFFrame *)frame {
    if (!self.isBroadcasting) {
        return;
    }
    
    if (encoder == _h264Encoder) {
        KFVideoFrame *videoFrame = (KFVideoFrame*)frame;
        [_hlsWriter processEncodedData:videoFrame.data presentationTimestamp:videoFrame.pts streamIndex:0 isKeyFrame:videoFrame.isKeyFrame];
    } else if (encoder == _aacEncoder) {
        [_hlsWriter processEncodedData:frame.data presentationTimestamp:frame.pts streamIndex:1 isKeyFrame:NO];
    }
}

#pragma mark AVCaptureOutputDelegate method
- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!self.isBroadcasting) {
        return;
    }
    // pass frame to encoders
    BOOL result = YES;
    if (connection == _videoConnection) {
        if (!self.hasScreenshot) {
            self.hasScreenshot = YES;
            
            self.thumbnail = [self imageFromSampleBuffer:sampleBuffer];
            
            NSString *path = [self.hlsWriter.directoryPath stringByAppendingPathComponent:THUMBNAIL_FILE_NAME];
            NSData *imageData = UIImageJPEGRepresentation(self.thumbnail, POSTER_QUALITY);
            [imageData writeToFile:path atomically:NO];
            [self.hlsUploader uploadThumbnail:THUMBNAIL_FILE_NAME thumbnailType:THUMBNAIL_POSTER];
        }
        result = [_h264Encoder encodeSampleBuffer:sampleBuffer];
    } else if (connection == _audioConnection) {
        result = [_aacEncoder encodeSampleBuffer:sampleBuffer];
    }
    
    if (result == NO) {
        [_h264Encoder shutdown];
        _h264Encoder = nil;
        [_aacEncoder shutdown];
        _aacEncoder = nil;
        [self stopBroadcasting];
    }
}

- (double)calculateNewVideoBitrate:(SegmentInfo *)segment numberOfQueuedSegments:(NSUInteger)numberOfQueuedSegments {
    double uploadSpeedKbs = segment.uploadSpeed * 8;
    double newVideoBitrate = 0.0;
    double uploadBitrate = uploadSpeedKbs * 1024; // bps
    
    double newBitrate = uploadBitrate * 0.6;
    //double newBitrate = uploadBitrate / ((numberOfQueuedSegments == 1 ? 0.5 : numberOfQueuedSegments) + 0.2);
    if (newBitrate > [VideoUtils maxBitrate]) {
        newBitrate = [VideoUtils maxBitrate];
    }
    
    if (newBitrate < [VideoUtils minBitrate]) {
        newBitrate = [VideoUtils minBitrate];
    }
    
    newVideoBitrate = newBitrate - self.aacEncoder.bitrate;
    if (newVideoBitrate < [VideoUtils minBitrate]) {
        newVideoBitrate = [VideoUtils minBitrate];
    }
    
    NSLog(@"----------- New video bitrate: %.1f Kb/s", newVideoBitrate / 1024);
    return newVideoBitrate;
}

#pragma mark - KFHLSUploaderDelegate
- (void) uploader:(KFHLSUploader *)uploader didUploadSegmentAtURL:(NSURL *)segmentURL segment:(SegmentInfo *)segment numberOfQueuedSegments:(NSUInteger)numberOfQueuedSegments {
    
    double uploadSpeedKbs = segment.uploadSpeed * 8;
    double segmentSize = segment.segmentSize/1024;
    Log(@"Uploaded segment %@ @ (%#.1fKB) %#.1f Kb/s, queued-segments %d", segmentURL, segmentSize, uploadSpeedKbs, numberOfQueuedSegments);
    
    self.h264Encoder.bitrate = [self calculateNewVideoBitrate:segment numberOfQueuedSegments:numberOfQueuedSegments];
    
    if ([self.delegate respondsToSelector:@selector(broadcastService:didDetermineBandwidth:calculatedBitrate:)]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate broadcastService:self didDetermineBandwidth:uploadSpeedKbs calculatedBitrate:self.h264Encoder.bitrate];
        });
    }
}

- (void) uploader:(KFHLSUploader*)uploader didDetectSegmentDrop:(SegmentInfo *)segment numberOfQueuedSegments:(NSUInteger)numberOfQueuedSegments {
    if ([self.delegate respondsToSelector:@selector(broadcastServiceDidDetectSegmentDrop:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate broadcastServiceDidDetectSegmentDrop:self];
        });
    }
}

- (void) uploader:(KFHLSUploader*)uploader didDetectSegmentDrops:(int)count numberOfQueuedSegments:(NSUInteger)numberOfQueuedSegments {
    if ([self.delegate respondsToSelector:@selector(broadcastServiceDidDetectSegmentsDrops:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate broadcastServiceDidDetectSegmentsDrops:self];
        });
    }
}

- (void) uploader:(KFHLSUploader *)uploader liveManifestReadyAtURL:(NSURL *)manifestURL {
    if (!self.isBroadcasting) {
        return;
    }
    
    [self.wsBinding streamingStarted:self.stream success:^(Stream *stream) {
        self.stream.state = kStreamStateStreaming;
        Log(@"Stream state - STREAMING");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate broadcastService:self didStartStreaming:self.stream];
        });
        
    } failure:^(NSError *error) {
        Log(@"Error update stream state: %@", error);
        [self stopBroadcasting];
    }];
}

- (bool) uploader:(KFHLSUploader *)uploader thumbnailUploadFailed:(SegmentInfo *)thumbnailInfo error:(NSError *)error {
    if ([thumbnailInfo.manifest isEqualToString:THUMBNAIL_WIDE]) {
        return true;
    }
    
    if (![self.delegate broadcastServiceUploadWideThumbnail:self]) {
        return true;
    }
    
    return false;
}

- (bool) uploader:(KFHLSUploader *)uploader thumbnailUploaded:(SegmentInfo *)thumbnailInfo {
    
    if ([self.delegate respondsToSelector:@selector(broadcastService:didUploadThumbnail:ofType:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate broadcastService:self didUploadThumbnail:thumbnailInfo.url ofType:thumbnailInfo.manifest];
        });
    }
    
    if ([thumbnailInfo.manifest isEqualToString:THUMBNAIL_POSTER]) {
        
        if (!self.isBroadcasting) {
            LogMethodEnd
            return false;
        }
        
        [self.wsBinding streamReady:self.stream success:^(Stream *stream) {
            Log(@"Stream state - READY");
            self.stream.state = kStreamStateReady;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate broadcastService:self streamReady:self.stream];
            });
            
        } failure:^(NSError *error) {
            Log(@"Error update stream state: %@", error);
            [self stopBroadcasting];
        }];
        
        /// Upload WIDE poster if enabled
        if ([self.delegate broadcastServiceUploadWideThumbnail:self]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                UIImage * wideThumbnail = [self.delegate broadcastService:self createWideThumbnail:self.thumbnail];
                self.thumbnail = nil;
                if (wideThumbnail) {
                    NSData * wideImageData = UIImagePNGRepresentation(wideThumbnail);
                    NSString *path = [self.hlsWriter.directoryPath stringByAppendingPathComponent:WIDE_THUMBNAIL_FILE_NAME];
                    [wideImageData writeToFile:path atomically:NO];
                    [uploader uploadThumbnail:WIDE_THUMBNAIL_FILE_NAME thumbnailType:THUMBNAIL_WIDE];
                } else {
                    [uploader setIsVideoUploadEnabled:true];
                }
            });
            
            return false;
        }
    }
    
    self.thumbnail = nil;
    return true;
}

- (void) uploaderHasFinished:(KFHLSUploader*)uploader {
    LogMethodStart;
    
    [[UIApplication sharedApplication] setIdleTimerDisabled: NO];
    [[KFHLSMonitor sharedMonitor] uploaderHasFinished:uploader];
    
    self.hlsUploader.delegate = nil;
    self.hlsUploader = nil;
    
    self.h264Encoder.delegate = nil;
    self.aacEncoder.delegate = nil;
    self.h264Encoder = nil;
    self.aacEncoder = nil;
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate broadcastServiceDidStopBroadcasting:self stream:self.stream];
    });
    
    LogMethodEnd;
}

#pragma mark - Location
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    self.lastLocation = [locations lastObject];
    
    if (self.stream == nil || !self.lastLocation || self.stream.location) {
        return;
    }
    
    if (self.stream && !self.stream.location) {
        if (!self.isBroadcasting) {
            [self.locationManager stopUpdatingLocation];
            LogMethodEnd
            return;
        }
        
        self.stream.location = [Location new];
        self.stream.location.longitude = self.lastLocation.coordinate.longitude;
        self.stream.location.latitude = self.lastLocation.coordinate.latitude;

        [self.wsBinding updateStream:self.stream success:^(Stream *stream) {
            Log(@"Location updated: %@", stream.uuid);
            [self.locationManager stopUpdatingLocation];
        } failure:^(NSError *error) {
            // update failed , try update againg
            self.stream.location = nil;
            LogError(@"Error update stream state: %@", error);
        }];
        
    }
}

@end
