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
//  User.m
//  moments
//
//  Created by MobileMan GmbH on 20.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "User.h"

@implementation User

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uuid forKey:@"uuid"];
    [aCoder encodeObject:self.facebookID forKey:@"facebookID"];
    [aCoder encodeObject:self.account forKey:@"account"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.firstName forKey:@"firstName"];
    [aCoder encodeObject:self.lastName forKey:@"lastName"];
    [aCoder encodeInt:self.gender forKey:@"gender"];
    [aCoder encodeObject:self.version forKey:@"version"];
    [aCoder encodeObject:self.signedInOn forKey:@"signedInOn"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
        self.facebookID = [aDecoder decodeObjectForKey:@"facebookID"];
        self.account = [aDecoder decodeObjectForKey:@"account"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.firstName = [aDecoder decodeObjectForKey:@"firstName"];
        self.lastName = [aDecoder decodeObjectForKey:@"lastName"];
        self.gender = [aDecoder decodeIntForKey:@"gender"];
        self.version = [aDecoder decodeObjectForKey:@"version"];
        self.signedInOn = [aDecoder decodeObjectForKey:@"signedInOn"];
    }
    
    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             NSStringFromSelector(@selector(uuid)): @"id",
             NSStringFromSelector(@selector(facebookID)): @"facebookId",
             NSStringFromSelector(@selector(name)): @"userName",
             NSStringFromSelector(@selector(firstName)): @"firstName",
             NSStringFromSelector(@selector(lastName)): @"lastName",
             NSStringFromSelector(@selector(gender)): @"gender",
             NSStringFromSelector(@selector(account)): @"account",
             NSStringFromSelector(@selector(version)): @"version",
             NSStringFromSelector(@selector(signedInOn)): @"signedInOn",
             };
}

@end
