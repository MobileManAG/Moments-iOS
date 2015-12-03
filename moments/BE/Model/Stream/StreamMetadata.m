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
//  StreamMetadata.m
//  moments
//
//  Created by MobileMan GmbH on 28.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "StreamMetadata.h"
#import "Comment.h"
#import "User.h"

@implementation StreamMetadata

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             NSStringFromSelector(@selector(state)): @"state",
             NSStringFromSelector(@selector(watchersCount)): @"watchersCount"
             };
}

- (bool)isStreamClosed {
    return self.state == kStreamStateClosed;
}

+ (instancetype)createFromJSON:(NSDictionary *)jsonData {
    
    NSError * error = nil;
    StreamMetadata * metadata = [MTLJSONAdapter modelOfClass:[StreamMetadata class] fromJSONDictionary:jsonData error:&error];
    
    ////////////////////
    NSMutableArray * events = [NSMutableArray arrayWithCapacity:100];
    metadata.events = events;
    
    Location * location = [MTLJSONAdapter modelOfClass:[Location class] fromJSONDictionary:[jsonData objectForKey:@"location"] error:&error];
    metadata.location = location;
    
    NSArray * eventsData = jsonData[@"events"];
    for (NSDictionary * commentData in eventsData) {
        Comment * comment = [MTLJSONAdapter modelOfClass:[Comment class] fromJSONDictionary:commentData error:&error];
        comment.author = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:commentData[@"author"] error:&error];
        [events addObject:comment];
    }
    
    return metadata;
}

@end
