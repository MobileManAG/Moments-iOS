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
//  VerticalButton.m
//  moments
//
//  Created by MobileMan GmbH on 07/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "VerticalButton.h"

@implementation VerticalButton

- (void)commonInit
{
    self.verticalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    [self addSubview:self.verticalImageView];
}

- (id)initWithFrame:(CGRect)aRect
{
    if ((self = [super initWithFrame:aRect])) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    if ((self = [super initWithCoder:coder])) {
        [self commonInit];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    // Center image
    CGPoint center = self.verticalImageView.center;
    center.x = self.frame.size.width/2;
    center.y = self.verticalImageView.frame.size.height/2 + 10;
    self.verticalImageView.center = center;
    
    //Center text
    CGRect newFrame = [self titleLabel].frame;
    newFrame.origin.x = 0;
    newFrame.origin.y = self.verticalImageView.frame.size.height + 15;
    newFrame.size.width = self.frame.size.width;
    
    self.titleLabel.frame = newFrame;
    
}

- (void) setSemitransparent:(BOOL)semitransparent
{
    if (semitransparent) {
        self.verticalImageView.alpha = .5;
    } else {
        self.verticalImageView.alpha = 1.0;
    }
}
@end
