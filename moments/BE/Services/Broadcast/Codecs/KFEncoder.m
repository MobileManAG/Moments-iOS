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
//  KFEncoder.m
//  Kickflip
//
//  Created by Christopher Ballinger on 2/16/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFEncoder.h"

@implementation KFEncoder

- (instancetype) initWithBitrate:(NSUInteger)bitrate {
    if (self = [super init]) {
        self.bitrate = bitrate;
        self.callbackQueue = dispatch_queue_create("KFEncoder Callback Queue", NULL);
    }
    return self;
}

- (void)shutdown {
    
}

@end