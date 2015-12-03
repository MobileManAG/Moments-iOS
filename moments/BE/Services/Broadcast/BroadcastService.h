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
//  BroadcastService.h
//  moments
//
//  Created by MobileMan GmbH on 15.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

@import AVFoundation;

@class CLLocation;
@class Stream;
@protocol BroadcastServiceDelegate;

@protocol BroadcastService <NSObject>

@property (nonatomic, readonly, strong) AVCaptureSession * session;
@property (assign, readonly, getter=isBroadcasting) bool broadcasting;
@property (nonatomic, weak) id<BroadcastServiceDelegate> delegate;

- (void)startBroadcasting:(NSString *)text location:(CLLocation *)location;
- (void)stopBroadcasting;

- (void)switchCameraWithPosition:(AVCaptureDevicePosition)position;
- (void)switchCamera:(void (^)(NSError *error))failure;

- (void)setVideoSessionPreset:(NSString *)videoSessionPreset failure:(void (^)(NSError *error))failure;

@end

@protocol BroadcastServiceDelegate <NSObject>

@required

- (void)broadcastService:(id<BroadcastService>)service didStopRunningWithError:(NSError *)error;

- (void)broadcastService:(id<BroadcastService>)service streamReady:(Stream *)stream;
- (void)broadcastService:(id<BroadcastService>)service didStartStreaming:(Stream *)stream;

- (void)broadcastServiceDidStartBroadcasting:(id<BroadcastService>)service stream:(Stream *)stream;

- (void)broadcastServiceDidStopBroadcasting:(id<BroadcastService>)service stream:(Stream *)stream;

- (void)broadcastService:(id<BroadcastService>)service didStopBroadcastingWithError:(NSError *)error;

- (bool)broadcastServiceUploadWideThumbnail:(id<BroadcastService>)service;
- (UIImage *)broadcastService:(id<BroadcastService>)service createWideThumbnail:(UIImage *)thumbnail;

@optional
- (void)broadcastService:(id<BroadcastService>)service didDetermineBandwidth:(double)bandwith calculatedBitrate:(double)calculatedBitrate;
- (void)broadcastServiceDidDetectSegmentsDrops:(id<BroadcastService>)service;
- (void)broadcastServiceDidDetectSegmentDrop:(id<BroadcastService>)service;
- (void)broadcastService:(id<BroadcastService>)service didUploadThumbnail:(NSString *)url ofType:(NSString *)ofType;


@end