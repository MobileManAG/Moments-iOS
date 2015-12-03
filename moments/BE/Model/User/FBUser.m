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
//  FBUser.m
//  moments
//
//  Created by MobileMan GmbH on 21.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "FBUser.h"

@implementation FBUser


+ (instancetype)createWithFacebookData:(NSDictionary *)data {
    NSError * error = nil;
    FBUser *user = [MTLJSONAdapter modelOfClass:[FBUser class] fromJSONDictionary:data error:&error];
    return user;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    
     return @{
              NSStringFromSelector(@selector(name)): @"name",
              NSStringFromSelector(@selector(email)): @"email",
              NSStringFromSelector(@selector(facebookID)): @"id",
              NSStringFromSelector(@selector(firstName)): @"first_name",
              NSStringFromSelector(@selector(lastName)): @"last_name",
              NSStringFromSelector(@selector(name)): @"name",
              NSStringFromSelector(@selector(gender)): @"gender",
              };
    
}

+ (Gender)genderFromFBGender:(NSString *)gender {
    if ([gender isEqualToString:FB_GENDER_MALE]) {
        return kGenderMale;
    } else if ([gender isEqualToString:FB_GENDER_FEMALE]) {
        return kGenderFemale;
    } else {
        return kGenderUnknown;
    }
}

@end
