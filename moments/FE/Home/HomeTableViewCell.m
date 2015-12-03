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
//  HomeTableViewCell.m
//  moments
//
//  Created by MobileMan GmbH on 17/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "HomeTableViewCell.h"
#import "fe_defines.h"
#import "UIImageView+Haneke.h"

@implementation HomeTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        // Initialization code
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
        
        self.userNameLabel = [[UILabel alloc] init];
        self.userNameLabel.font = MOMENTS_FONT_TITLE_2;
        self.userNameLabel.textColor = [UIColor whiteColor];
        self.userNameLabel.textAlignment = NSTextAlignmentLeft;
        //self.userNameLabel.backgroundColor = [UIColor redColor];
        [self.contentView addSubview:self.userNameLabel];
        
        CGFloat size = USER_THUMBNAIL_SIZE;
        
        self.userImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
        self.userImageView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        self.userImageView.layer.cornerRadius = size/2;
        self.userImageView.clipsToBounds = YES;
        self.userImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.userImageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"thumbnail"];
        [self.contentView addSubview:self.userImageView];
        
        self.watchButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        [self.watchButton addTarget:self action:@selector(didPushWatchButton) forControlEvents:UIControlEventTouchUpInside];
        self.watchButton.backgroundColor = MOMENTS_COLOR_YELLOW_SEMITRANSPARENT;
        [self.watchButton setTitle:@"WATCH" forState:UIControlStateNormal];
        [self.watchButton setTitle:@"WATCH" forState:UIControlStateHighlighted];
        [[self.watchButton titleLabel] setTextColor:MOMENTS_COLOR_BLACK];
        [self.watchButton setTitleColor:MOMENTS_COLOR_BLACK forState:UIControlStateNormal];
        [self.watchButton setTitleColor:MOMENTS_COLOR_WHITE forState:UIControlStateHighlighted];
        [[self.watchButton titleLabel] setFont:MOMENTS_FONT_DISPLAY_1];
        [[self.watchButton titleLabel] setTextAlignment:NSTextAlignmentCenter];
        [self.contentView addSubview:self.watchButton];
        
        self.userImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.userNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.watchButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|-16.0-[_userImageView(48.0)]|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_userImageView)]];
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"V:|-12.0-[_userImageView(48.0)]-12.0-|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_userImageView)]];
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|-80-[_userNameLabel]-116-|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_userNameLabel)]];
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"V:|-16-[_userNameLabel]-16-|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_userNameLabel)]];
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:[_watchButton(100.0)]-16-|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_watchButton)]];
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"V:|-12-[_watchButton(48.0)]-12-|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_watchButton)]];
        
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.user = nil;
    self.userNameLabel.text = @"";
    [self.userImageView hnk_cancelSetImage];
    self.userImageView.image = nil;
    self.isFirstCell = NO;
}

- (void) didPushWatchButton
{
    if ([self.delegate respondsToSelector:@selector(didSelectWatchOf:)]) {
        [self.delegate didSelectWatchOf:self.user];
    }
}

@end
