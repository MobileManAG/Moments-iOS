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
//  FriendsTableViewCell.m
//  moments
//
//  Created by MobileMan GmbH on 27/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "FriendsTableViewCell.h"
#import "User.h"
#import "fe_defines.h"
#import "UIImageView+Haneke.h"

@implementation FriendsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
        self.userNameLabel = [[UILabel alloc] init];
        self.userNameLabel.font = MOMENTS_FONT_TITLE_2;
        self.userNameLabel.textColor = [UIColor blackColor];
        self.userNameLabel.textAlignment = NSTextAlignmentLeft;
        //self.userNameLabel.backgroundColor = [UIColor yellowColor];
        [self.contentView addSubview:self.userNameLabel];
        
        self.isNewFriendLabel = [[UILabel alloc] init];
        self.isNewFriendLabel.text = @"NEW";
        self.isNewFriendLabel.font = MOMENTS_FONT_CAPTION;
        self.isNewFriendLabel.textColor = MOMENTS_COLOR_RED;
        self.isNewFriendLabel.textAlignment = NSTextAlignmentLeft;
        self.isNewFriendLabel.hidden = YES;
        [self.contentView addSubview:self.isNewFriendLabel];
        
        
        self.isBlockedFriendLabel = [[UILabel alloc] init];
        self.isBlockedFriendLabel.text = @"BLOCKED";
        self.isBlockedFriendLabel.font = MOMENTS_FONT_CAPTION;
        self.isBlockedFriendLabel.textColor = MOMENTS_COLOR_GREY;
        self.isBlockedFriendLabel.textAlignment = NSTextAlignmentLeft;
        self.isBlockedFriendLabel.hidden = YES;
        [self.contentView addSubview:self.isBlockedFriendLabel];
        
        CGFloat size = USER_THUMBNAIL_SIZE;
        
        self.userImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
        self.userImageView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        self.userImageView.layer.cornerRadius = size/2;
        self.userImageView.clipsToBounds = YES;
        self.userImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.userImageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"thumbnail"];
        [self.contentView addSubview:self.userImageView];
        
        self.userNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.isNewFriendLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.isBlockedFriendLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.userImageView.translatesAutoresizingMaskIntoConstraints = NO;
                
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|-80.0-[_userNameLabel]-50.0-|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_userNameLabel)]];
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"V:|-16.0-[_userNameLabel]-16.0-|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_userNameLabel)]];
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|-80.0-[_isNewFriendLabel]-16.0-|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_isNewFriendLabel)]];
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"V:|-42.0-[_isNewFriendLabel(20.0)]-16.0-|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_isNewFriendLabel)]];
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|-80.0-[_isBlockedFriendLabel]-16.0-|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_isBlockedFriendLabel)]];
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"V:|-42.0-[_isBlockedFriendLabel(20.0)]-16.0-|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_isBlockedFriendLabel)]];
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|-16.0-[_userImageView(48.0)]|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_userImageView)]];
        [self.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"V:|-12.0-[_userImageView(48.0)]-12.0-|"
                                          options:NSLayoutFormatAlignAllLeft
                                          metrics:nil views:NSDictionaryOfVariableBindings(_userImageView)]];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.userNameLabel.text = @"";
    [self.userImageView hnk_cancelSetImage];
    self.userImageView.image = nil;
    self.isFirstCell = NO;
    self.isNewFriend = NO;
    self.isNewFriendLabel.hidden = YES;
    self.isBlockedFriend = NO;
    self.isBlockedFriendLabel.hidden = YES;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //blocked friend
    if (self.isBlockedFriend) {
        self.isBlockedFriendLabel.hidden = NO;
    } else {
        //new friend
        if (self.isNewFriend) {
            self.isNewFriendLabel.hidden = NO;
        }
    }
    
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
