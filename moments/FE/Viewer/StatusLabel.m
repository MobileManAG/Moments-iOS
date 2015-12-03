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
//  StatusLabel.m
//  moments
//
//  Created by MobileMan GmbH on 30/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "StatusLabel.h"

@implementation StatusLabel

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.edgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.edgeInsets)];
}

-(CGSize)intrinsicContentSize {
    CGSize contentSize = [super intrinsicContentSize];
    UIEdgeInsets insets = self.edgeInsets;
    contentSize.height += insets.top + insets.bottom;
    contentSize.width += insets.left + insets.right;
    return contentSize;
}

@end
