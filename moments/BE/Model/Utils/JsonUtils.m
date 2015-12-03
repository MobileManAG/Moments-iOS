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
//  JsonUtils.m
//  moments
//
//  Created by MobileMan GmbH on 21.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "JsonUtils.h"
#import "User.h"
#import "FBUser.h"
#import <Mantle/Mantle.h>

@implementation JsonUtils

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             NSStringFromSelector(@selector(uuid)): @"id",
             NSStringFromSelector(@selector(facebookID)): @"facebookId",
             NSStringFromSelector(@selector(name)): @"userName",
             NSStringFromSelector(@selector(gender)): @"gender",
             NSStringFromSelector(@selector(email)): @"email",
             };
}

+ (NSDictionary *)FBJSONKeyPathsByPropertyKey {
    return @{
             NSStringFromSelector(@selector(name)): @"name",
             NSStringFromSelector(@selector(facebookID)): @"id",
             NSStringFromSelector(@selector(firstName)): @"first_name",
             NSStringFromSelector(@selector(lastName)): @"last_name",
             NSStringFromSelector(@selector(gender)): @"gender",
             NSStringFromSelector(@selector(email)): @"email",
             };
}

+ (MTLModel *)fbUserModel {
    MTLModel * model = [MTLModel modelWithDictionary:[self FBJSONKeyPathsByPropertyKey] error:nil];
    return model;
}

+ (MTLModel *)userModel {
    MTLModel * model = [MTLModel modelWithDictionary:[self JSONKeyPathsByPropertyKey] error:nil];
    return model;
}

@end
