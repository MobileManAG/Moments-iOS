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
//  ServiceFactory.m
//  moments
//
//  Created by MobileMan GmbH on 15.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "ServiceFactory.h"
#import "BroadcastServiceImpl.h"
#import "UserServiceImpl.h"
#import "SystemServiceImpl.h"
#import "StreamServiceImpl.h"

@implementation ServiceFactory

+(id<BroadcastService>)broadcastService {
    static BroadcastServiceImpl *service = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[BroadcastServiceImpl alloc] init];
    });
    
    return service;
}

+(id<UserService>)userService {
    
    static UserServiceImpl *service = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[UserServiceImpl alloc] init];
    });
    return service;
}

+(id<SystemService>)systemService {
    static SystemServiceImpl *service = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[SystemServiceImpl alloc] init];
    });
    return service;
}

+(id<StreamService>)streamService:(id<StreamServiceDelegate>)delegate {
    id<StreamService> service = [[StreamServiceImpl alloc] initWithDelegate:delegate];
    return service;
}

@end
