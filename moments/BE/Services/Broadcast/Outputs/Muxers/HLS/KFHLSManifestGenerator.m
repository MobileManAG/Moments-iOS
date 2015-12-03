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
//  KFHLSManifestGenerator.m
//  Kickflip
//
//  Created by Christopher Ballinger on 10/1/13.
//  Copyright (c) 2013 OpenWatch, Inc. All rights reserved.
//


#import "KFHLSManifestGenerator.h"
#import "SegmentInfo.h"

#define EXTINF @"#EXTINF:"
#define EXTINF_LENGTH 8

@interface KFHLSManifestGenerator()
@property (nonatomic, strong) NSMutableString *segmentsString;
@property (nonatomic) BOOL finished;
@property (nonatomic, strong) NSMutableSet * processedSegmentIndexes;

@end

@implementation KFHLSManifestGenerator

- (NSMutableString*) header {
    NSMutableString *header = [NSMutableString stringWithFormat:@"#EXTM3U\n#EXT-X-VERSION:%lu\n#EXT-X-TARGETDURATION:%d\n", (unsigned long)self.version, (int)self.targetDuration];
    NSString *type = nil;
    if (self.playlistType == KFHLSManifestPlaylistTypeVOD) {
        type = @"VOD";
    } else if (self.playlistType == KFHLSManifestPlaylistTypeEvent) {
        type = @"EVENT";
    }
    if (type) {
        [header appendFormat:@"#EXT-X-PLAYLIST-TYPE:%@\n", type];
    }
    [header appendFormat:@"#EXT-X-MEDIA-SEQUENCE:%ld\n", (long)self.mediaSequence];
    return header;
}

- (NSString*) footer {
    return @"#EXT-X-ENDLIST\n";
}

- (id) initWithTargetDuration:(float)targetDuration playlistType:(KFHLSManifestPlaylistType)playlistType {
    if (self = [super init]) {
        self.targetDuration = targetDuration;
        self.playlistType = playlistType;
        self.version = 3;
        self.mediaSequence = -1;
        self.segmentsString = [NSMutableString string];
        self.finished = NO;
        self.processedSegmentIndexes = [NSMutableSet set];
    }
    return self;
}

- (void) appendFileName:(NSString *)fileName duration:(float)duration mediaSequence:(NSUInteger)mediaSequence {
    if (self.finished) {
        return;
    }
    self.mediaSequence = mediaSequence;
    if (duration > self.targetDuration) {
        self.targetDuration = duration;
    }
    
    [self.processedSegmentIndexes addObject:@(mediaSequence)];
    
    [self.segmentsString appendFormat:@"#EXTINF:%#.1f,\n%@\n", duration, fileName];
}

- (void) finalizeManifest {
    self.finished = YES;
    self.mediaSequence = 0;
}

- (NSString*) stripToNumbers:(NSString*)string {
    return [[string componentsSeparatedByCharactersInSet:
             [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
            componentsJoinedByString:@""];
}

- (void) addFailedSegment:(SegmentInfo *)segment {
    @synchronized(self.processedSegmentIndexes) {
        [self.processedSegmentIndexes addObject:segment.index];
    }
}

- (void) addSegment:(SegmentInfo *)segment {
    
    if (segment.index.intValue > self.mediaSequence) {
        
        NSArray *rawLines = [segment.manifest componentsSeparatedByString:@"\n"];
        NSMutableArray *lines = [NSMutableArray arrayWithCapacity:rawLines.count];
        for (NSString *line in rawLines) {
            if (!line.length) {
                continue;
            }
            if ([line isEqualToString:@"#EXT-X-ENDLIST"]) {
                continue;
            }
            [lines addObject:line];
        }
        if (lines.count < 6) {
            return;
        }
        
        NSString *segmentName = lines[lines.count-1];
        int segmentNumber = [[self stripToNumbers:segmentName] integerValue];
        @synchronized(self.processedSegmentIndexes) {
            if ([self.processedSegmentIndexes containsObject:@(segmentNumber)]) {
                return;
            }
        }
        
        NSString *extInf = lines[lines.count-2];
        NSString *extInfNumberString = [extInf substringFromIndex:EXTINF_LENGTH];
        extInfNumberString = [extInfNumberString substringToIndex:extInfNumberString.length - 1];
        
        float duration = [extInfNumberString floatValue];
        
        [self appendFileName:segmentName duration:duration mediaSequence:segmentNumber];
    }
    
    if (segment.isLastSegment) {
        [self.segmentsString appendString:@"#EXT-X-ENDLIST"];
    }
}

- (NSString*) manifestString {
    NSMutableString *manifest = [self header];
    [manifest appendString:self.segmentsString];
    if (self.finished) {
        [manifest appendString:[self footer]];
    }
    NSLog(@"Latest manifest:\n%@", manifest);
    return manifest;
}

@end
