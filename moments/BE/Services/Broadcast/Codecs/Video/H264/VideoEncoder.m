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
//  VideoEncoder.m
//  Encoder Demo
//
//  Created by Geraint Davies on 14/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "VideoEncoder.h"
#import "UIDevice-Hardware.h"
#import "VideoUtils.h"

@implementation VideoEncoder

@synthesize path = _path;

+ (VideoEncoder*) encoderForPath:(NSString*) path Height:(int) height andWidth:(int) width bitrate:(int)bitrate
{
    VideoEncoder* enc = [VideoEncoder alloc];
    [enc initPath:path Height:height andWidth:width bitrate:bitrate];
    return enc;
}

- (void)dealloc
{
    _writer = nil;
    _writerInput = nil;
}

-(CGAffineTransform) detectOrientation {
    CGAffineTransform playbackTransform;
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationUnknown:
            NULL;
        case UIDeviceOrientationFaceUp:
            NULL;
        case UIDeviceOrientationFaceDown:
            NULL;
            break;
        case UIDeviceOrientationPortrait:
            
            playbackTransform = CGAffineTransformMakeRotation( ( 90 * M_PI ) / 180 );
            break;
        case UIDeviceOrientationLandscapeLeft:
            
            // Transform depends on which camera is supplying video
            /*
            if (theProject.backCamera == YES) playbackTransform = CGAffineTransformMakeRotation( 0 / 180 );
            else playbackTransform = CGAffineTransformMakeRotation( ( -180 * M_PI ) / 180 );
            */
            playbackTransform = CGAffineTransformMakeRotation( 0 / 180 );
            break;
        case UIDeviceOrientationLandscapeRight:
            
            // Transform depends on which camera is supplying video
            /*
            if (theProject.backCamera == YES) playbackTransform = CGAffineTransformMakeRotation( ( -180 * M_PI ) / 180 );
            else playbackTransform = CGAffineTransformMakeRotation( 0 / 180 );
            */
            playbackTransform = CGAffineTransformMakeRotation( ( -180 * M_PI ) / 180 );
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            
            playbackTransform = CGAffineTransformMakeRotation( ( -90 * M_PI ) / 180 );
            break;
        default:
            playbackTransform = CGAffineTransformMakeRotation( 0 / 180 ); // Use the default, although there are likely other issues if we get here.
            break;
    }
    
    return playbackTransform;
}

- (void)setupWriter {
    [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
    NSURL* url = [NSURL fileURLWithPath:self.path];
    
    _writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeQuickTimeMovie error:nil];
    NSDictionary* settings = @{
                               AVVideoCodecKey: AVVideoCodecH264,
                               AVVideoWidthKey: @(_width),
                               AVVideoHeightKey: @(_height),
                               AVVideoCompressionPropertiesKey: @{
                                       AVVideoAverageBitRateKey: @(self.bitrate),
                                       AVVideoMaxKeyFrameIntervalKey: @(150),
                                       AVVideoProfileLevelKey: [VideoUtils videoCodecProfile],
                                       AVVideoAllowFrameReorderingKey: @NO,
                                       AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCAVLC,
                                       AVVideoExpectedSourceFrameRateKey: @([VideoUtils videoFrameRate]),
                                       //AVVideoAverageNonDroppableFrameRateKey: @([VideoUtils videoFrameRate])
                                       }
                               };
    
    if ([_writer canApplyOutputSettings:settings forMediaType:AVMediaTypeVideo]) {
        _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
        _writerInput.expectsMediaDataInRealTime = YES;
        //CGAffineTransform playbackTransform = [self detectOrientation];
        //_writerInput.transform = CGAffineTransformMakeRotation(M_PI/2);
        
        if ([_writer canAddInput:_writerInput]) {
            [_writer addInput:_writerInput];
        }
    }
}

- (void) initPath:(NSString*)path Height:(int) height andWidth:(int) width bitrate:(int)bitrate
{
    self.path = path;
    _bitrate = bitrate;
    _height = height;
    _width = width;
    [self setupWriter];
}

- (AVAssetWriterStatus)status {
    return _writer.status;
}

- (void) finishWithCompletionHandler:(void (^)(void))handler
{
    [_writerInput markAsFinished];
    if (_writer.status == AVAssetWriterStatusWriting) {
        [_writer finishWritingWithCompletionHandler: handler];
    } else {
        [_writer cancelWriting];
        handler();
    }
}

- (BOOL) encodeFrame:(CMSampleBufferRef) sampleBuffer
{
    if (CMSampleBufferDataIsReady(sampleBuffer))
    {
        if (_writer.status == AVAssetWriterStatusUnknown)
        {
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [_writer startWriting];
            [_writer startSessionAtSourceTime:startTime];
        }
        
        if (_writer.status == AVAssetWriterStatusFailed)
        {
            NSLog(@"VideoEncoder.encodeFrame: Writer error %@", _writer.error);
            return NO;
        }
        
        if (_writerInput.readyForMoreMediaData == YES)
        {
            [_writerInput appendSampleBuffer:sampleBuffer];
            return YES;
        }
    }
    return NO;
}

@end
