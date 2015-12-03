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
//  KFEncoder.h
//  Kickflip
//
//  Created by Christopher Ballinger on 2/14/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class KFFrame, KFEncoder;

@protocol KFSampleBufferEncoder <NSObject>
- (BOOL) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

@protocol KFEncoderDelegate <NSObject>
- (void) encoder:(KFEncoder*)encoder encodedFrame:(KFFrame*)frame;
@end

@interface KFEncoder : NSObject

@property (nonatomic) NSUInteger bitrate;
@property (nonatomic) dispatch_queue_t callbackQueue;
@property (nonatomic, weak) id<KFEncoderDelegate> delegate;

- (instancetype) initWithBitrate:(NSUInteger)bitrate;
- (void)shutdown;

@end