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
//  VideoUtils.m
//  moments
//
//  Created by MobileMan GmbH on 4.5.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

@import UIKit;
@import AVFoundation;
@import CoreTelephony;
#import "UIDevice-Hardware.h"
#import "VideoUtils.h"
#import "mom_defines.h"

#define _HLS_SEGMENTS_DURATION 7
#define _HLS_SEGMENTS_COUNT 5

#define MIN_BITRATE 200 * 1000 // 200 Kbps
#define MAX_BITRATE 300 * 1000 // 300 Kbps

#define AUDIO_BITRATE 32 * 1000 // 6 Kbps
#define AUDIO_SAMPLE_RATE 44100

#define H264_VIDEO_PROFILE_LEVEL AVVideoProfileLevelH264Baseline30
#define VIDEO_SESSION_PRESET AVCaptureSessionPreset640x480


static double _videoMinBitrate = .0;
static double _videoMaxBitrate = .0;
static NSString * _deviceModel = nil;

static int _hlsSegmentsCount = 3;
static int _hlsSegmentsDuration = 4;
static int _videoFrameRate = 0;

static NSString * _videoSessionPreset = nil;
static NSString * _videoCodecProfile = nil;

@implementation VideoUtils

+ (void)initialize {
    
    _deviceModel = [[UIDevice currentDevice] modelName];
    
    _videoFrameRate = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"_videoFrameRate"];
    _hlsSegmentsCount = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"_hlsSegmentsCount"];
    _hlsSegmentsDuration = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"_hlsSegmentsDuration"];
    _videoMinBitrate = [[NSUserDefaults standardUserDefaults] doubleForKey:@"_videoMinBitrate"];
    _videoMaxBitrate = [[NSUserDefaults standardUserDefaults] doubleForKey:@"_videoMaxBitrate"];
    _videoSessionPreset = [[NSUserDefaults standardUserDefaults] stringForKey:@"_videoSessionPreset"];
    _videoCodecProfile = [[NSUserDefaults standardUserDefaults] stringForKey:@"_videoCodecProfile"];

    if (_videoFrameRate == 0) {
        if ( [NSProcessInfo processInfo].processorCount == 1 ) {
            _videoFrameRate = 15;
        } else {
            _videoFrameRate = 25;
        }
    }
    
    if (_hlsSegmentsCount == 0) {
        _hlsSegmentsCount = _HLS_SEGMENTS_COUNT;
    }
    
    if (_hlsSegmentsDuration == 0) {
        _hlsSegmentsDuration = _HLS_SEGMENTS_DURATION;
    }
    
    if (_videoMinBitrate == .0) {
        _videoMinBitrate = MIN_BITRATE;
    }
    
    if (_videoMaxBitrate == .0) {
        _videoMaxBitrate = MAX_BITRATE;
    }

    if (_videoCodecProfile == nil) {
        _videoCodecProfile = H264_VIDEO_PROFILE_LEVEL;
    }
    
    if (_videoSessionPreset == nil) {
        _videoSessionPreset = VIDEO_SESSION_PRESET;
    }
}

+ (int)audioBitrate {
    return AUDIO_BITRATE;
}

+ (int)audioSamplerate {
    return AUDIO_SAMPLE_RATE;
}

+ (double)minBitrate {
    return _videoMinBitrate;
}

+ (void)setMinBitrate:(double)bitrate {
    _videoMinBitrate = bitrate;
    [[NSUserDefaults standardUserDefaults] setDouble:bitrate forKey:@"_videoMinBitrate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (double)maxBitrate {
    return _videoMaxBitrate;
}

+ (void)setMaxBitrate:(double)bitrate {
    _videoMaxBitrate = bitrate;
    [[NSUserDefaults standardUserDefaults] setDouble:bitrate forKey:@"_videoMaxBitrate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (int)videoSegmentsCount {
    return _hlsSegmentsCount;
}

+ (void)setVideoSegmentsCount:(int)count {
    _hlsSegmentsCount = count;
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:@"_hlsSegmentsCount"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (int)videoSegmentsDuration {
    return _hlsSegmentsDuration;
}

+ (void)setVideoSegmentsDuration:(int)duration {
    _hlsSegmentsDuration = duration;
    [[NSUserDefaults standardUserDefaults] setInteger:duration forKey:@"_hlsSegmentsDuration"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)videoSessionPreset {
    return _videoSessionPreset;
}

+ (void)setVideoSessionPreset:(NSString *)videoSessionPreset {
    _videoSessionPreset = videoSessionPreset;
    [[NSUserDefaults standardUserDefaults] setObject:videoSessionPreset forKey:@"_videoSessionPreset"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray *)availableVideoSessionPreset {
    return @[
             AVCaptureSessionPresetLow,
             AVCaptureSessionPresetMedium,
             AVCaptureSessionPresetHigh,
             AVCaptureSessionPreset352x288,
             AVCaptureSessionPreset640x480,
             AVCaptureSessionPreset1280x720,
             AVCaptureSessionPreset1920x1080,
             VIDEO_PRESET_AUTO
             ];
}

+ (NSString *)videoSessionPreset:(NetworkStatus)networkStatus mobileNetworkType:(NSString *)mobileNetworkType {
    
    if (_videoSessionPreset && ![VIDEO_PRESET_AUTO isEqualToString:_videoSessionPreset]) {
        return _videoSessionPreset;
    }
        
    NSString *sessionPreset = AVCaptureSessionPresetLow;
    //NSString * deviceModel = [[UIDevice currentDevice] modelName];
    // For single core systems like iPhone 4 and iPod Touch 4th Generation we use a lower resolution and framerate to maintain real-time performance.
    if ( [NSProcessInfo processInfo].processorCount == 1 ) {
        //
        if (networkStatus == ReachableViaWiFi) {
            sessionPreset = AVCaptureSessionPresetMedium;
        } else if ([mobileNetworkType isEqualToString:CTRadioAccessTechnologyGPRS]) {
            sessionPreset = AVCaptureSessionPresetLow;
        } else if ([mobileNetworkType isEqualToString:CTRadioAccessTechnologyEdge]) {
            sessionPreset = AVCaptureSessionPreset352x288;
        } else {
            sessionPreset = AVCaptureSessionPresetMedium;
        }
        
    } else {
        if (networkStatus == ReachableViaWiFi) {
            sessionPreset = AVCaptureSessionPreset640x480;
        } else if ([mobileNetworkType isEqualToString:CTRadioAccessTechnologyGPRS]) {
            sessionPreset = AVCaptureSessionPresetLow;
        } else if ([mobileNetworkType isEqualToString:CTRadioAccessTechnologyEdge]) {
            sessionPreset = AVCaptureSessionPreset352x288;
        } else {
            sessionPreset = AVCaptureSessionPresetMedium;
        }
    }
    
    return sessionPreset;
}

+ (void)setVideoFrameRate:(int)frameRate {
    _videoFrameRate = frameRate;
    [[NSUserDefaults standardUserDefaults] setInteger:frameRate forKey:@"_videoFrameRate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (int)videoFrameRate {
    return _videoFrameRate;
}

+ (NSArray *)availableVideoCodecProfiles {
    return @[
             AVVideoProfileLevelH264Baseline30,
             AVVideoProfileLevelH264Baseline31,
             AVVideoProfileLevelH264Baseline41,
             AVVideoProfileLevelH264BaselineAutoLevel,
             AVVideoProfileLevelH264Main30,
             AVVideoProfileLevelH264Main31,
             AVVideoProfileLevelH264Main32,
             AVVideoProfileLevelH264Main41,
             AVVideoProfileLevelH264MainAutoLevel,
             AVVideoProfileLevelH264High40,
             AVVideoProfileLevelH264High41,
             AVVideoProfileLevelH264HighAutoLevel,
             ];
}

+ (NSString *)videoCodecProfile {
    return _videoCodecProfile;
}

+ (void)setVideoCodecProfile:(NSString *)videoCodecProfile {
    _videoCodecProfile = videoCodecProfile;
    [[NSUserDefaults standardUserDefaults] setObject:videoCodecProfile forKey:@"_videoCodecProfile"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
@end
