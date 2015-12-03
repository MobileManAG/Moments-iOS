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
//  ShareTableViewCell.m
//  moments
//
//  Created by MobileMan GmbH on 27/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "ShareTableViewCell.h"
#import "fe_defines.h"

@implementation ShareTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = MOMENTS_FONT_TITLE_2;
        self.nameLabel.textColor = [UIColor blackColor];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.contentView addSubview:self.nameLabel];
        
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|-5-[_nameLabel]-5-|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_nameLabel)]];
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"V:|-5-[_nameLabel]-5-|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_nameLabel)]];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.nameLabel.text = @"";
    self.isFirstCell = NO;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //separator
    if (self.isFirstCell) {
        CGRect separatorRect = CGRectMake(0, 0, rect.size.width, 0.5);
        [[UIColor colorWithWhite:0.0 alpha:0.25] set];
        CGContextFillRect(context, separatorRect);
    }
    
    CGRect separatorRect = CGRectMake(0, rect.size.height-0.5, rect.size.width, 0.5);
    [[UIColor colorWithWhite:0.0 alpha:0.25] set];
    CGContextFillRect(context, separatorRect);
}

@end
