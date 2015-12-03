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
//  UserSession.m
//  moments
//
//  Created by MobileMan GmbH on 20.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "UserSession.h"
#import <Mantle/Mantle.h>
#import "User.h"
#import "UserAccount.h"
#import "FBUser.h"
#import "mom_defines.h"
#import "SSKeychain.h"

@implementation UserSession

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.user forKey:@"user"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.user = [aDecoder decodeObjectForKey:@"user"];
    }
    
    return self;
}

+ (instancetype)createWithUser:(User *)user {
    UserSession * session = [[UserSession alloc] init];
    session.user = user;
    
    [SSKeychain setPassword:user.account.token forService:MOM_APP_ID account:user.uuid];
    
    return session;
}

@end
