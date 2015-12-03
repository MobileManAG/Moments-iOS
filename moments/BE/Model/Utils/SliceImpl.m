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
//  SliceImpl.m
//  moments
//
//  Created by MobileMan GmbH on 24.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "SliceImpl.h"

@implementation SliceImpl

@synthesize number;
@synthesize size;
@synthesize numberOfElements;
@synthesize content;
@synthesize hasContent;
@synthesize isFirst;
@synthesize isLast;
@synthesize hasNext;
@synthesize hasPrevious;

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             NSStringFromSelector(@selector(number)): @"number",
             NSStringFromSelector(@selector(size)): @"size",
             NSStringFromSelector(@selector(numberOfElements)): @"numberOfElements",
             NSStringFromSelector(@selector(hasContent)): @"hasContent",
             NSStringFromSelector(@selector(isFirst)): @"isFirst",
             NSStringFromSelector(@selector(isLast)): @"isLast",
             NSStringFromSelector(@selector(hasNext)): @"hasNext",
             NSStringFromSelector(@selector(hasPrevious)): @"hasPrevious",
             };
}

+ (instancetype)createEmpty {
    SliceImpl * result = [SliceImpl new];
    result.numberOfElements = @(0);
    result.isFirst = true;
    result.isLast = true;
    result.size = @(0);
    result.number = @(0);
    return result;
}

@end
