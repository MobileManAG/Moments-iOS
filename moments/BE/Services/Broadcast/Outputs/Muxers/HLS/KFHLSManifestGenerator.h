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
//  KFHLSManifestGenerator.h
//  Kickflip
//
//  Created by Christopher Ballinger on 10/1/13.
//  Copyright (c) 2013 OpenWatch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SegmentInfo;

typedef NS_ENUM(NSUInteger, KFHLSManifestPlaylistType) {
    KFHLSManifestPlaylistTypeLive = 0,
    KFHLSManifestPlaylistTypeVOD,
    KFHLSManifestPlaylistTypeEvent
};

@interface KFHLSManifestGenerator : NSObject

@property (nonatomic) double targetDuration;
@property (nonatomic) NSInteger mediaSequence;
@property (nonatomic) NSUInteger version;
@property (nonatomic) KFHLSManifestPlaylistType playlistType;

- (id) initWithTargetDuration:(float)targetDuration playlistType:(KFHLSManifestPlaylistType)playlistType;

- (void) addSegment:(SegmentInfo *)segment;
- (void) addFailedSegment:(SegmentInfo *)segment;

- (void) finalizeManifest;

- (NSString*) manifestString;

@end
