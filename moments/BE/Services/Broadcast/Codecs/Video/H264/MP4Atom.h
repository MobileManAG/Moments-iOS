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
//  MP4Atom.h
//  Encoder Demo
//
//  Created by Geraint Davies on 15/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import <Foundation/Foundation.h>

@interface MP4Atom : NSObject

{
    NSFileHandle* _file;
    int64_t _offset;
    int64_t _length;
    OSType _type;
    int64_t _nextChild;
}
@property OSType type;
@property int64_t length;

+ (MP4Atom*) atomAt:(int64_t) offset size:(long long) length type:(OSType) fourcc inFile:(NSFileHandle*) handle;
- (BOOL) init:(int64_t) offset size:(long long) length type:(OSType) fourcc inFile:(NSFileHandle*) handle;
- (NSData*) readAt:(int64_t) offset size:(long long) length;
- (BOOL) setChildOffset:(int64_t) offset;
- (MP4Atom*) nextChild;
- (MP4Atom*) childOfType:(OSType) fourcc startAt:(int64_t) offset;

@end
