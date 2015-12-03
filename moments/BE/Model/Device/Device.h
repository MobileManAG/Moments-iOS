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
//  Device.h
//  moments
//
//  Created by MobileMan GmbH on 5.5.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <Mantle/Mantle.h>
#import "mom_defines.h"

@interface Device : MTLModel <MTLJSONSerializing, NSCoding>

@property (nonatomic, assign) DeviceType deviceType;

@end
