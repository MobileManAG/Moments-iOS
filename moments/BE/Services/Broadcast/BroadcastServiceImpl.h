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
//  BroadcastServiceImpl.h
//  moments
//
//  Created by MobileMan GmbH on 15.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

@import AVFoundation;
#import "BroadcastService.h"
#import "KFHLSUploader.h"
#import "WSBinding.h"

@class AVCaptureConnection;
@class AVCaptureSession;
@class AVCaptureVideoDataOutput;
@class AVCaptureAudioDataOutput;
@protocol Encoder, Stream;

@class KFAACEncoder, KFH264Encoder, KFHLSWriter;

@interface BroadcastServiceImpl : NSObject <BroadcastService, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, KFHLSUploaderDelegate>

@property (nonatomic, strong) id<Encoder> videEncoder;
@property (nonatomic, strong) id<Encoder> audioEncoder;

@property (assign, getter=isBroadcasting, readwrite) bool broadcasting;

@property (nonatomic, strong) id applicationWillEnterForegroundNotificationObserver;

@property (nonatomic, strong, readwrite) AVCaptureSession * session;

@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, strong) dispatch_queue_t audioQueue;

@property (nonatomic, strong) AVCaptureDeviceInput * videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput* videoOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput* audioOutput;

@property (nonatomic, strong) AVCaptureConnection* audioConnection;
@property (nonatomic, strong) AVCaptureConnection* videoConnection;
@property (nonatomic, strong) NSDictionary * recommendedVideoSettings;

@property(nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property(nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputAudioFormatDescription;

@property (nonatomic, strong) KFAACEncoder *aacEncoder;
@property (nonatomic, strong) KFH264Encoder *h264Encoder;
@property (nonatomic, strong) KFHLSWriter *hlsWriter;
@property (nonatomic, strong) Stream *stream;

@property (nonatomic) int videoWidth;
@property (nonatomic) int videoHeight;
@property (nonatomic) int audioSampleRate;

@property (nonatomic, strong) id<WSBinding> wsBinding;

-(id)initWithDelegate:(id<BroadcastServiceDelegate>)delegate;


@end
