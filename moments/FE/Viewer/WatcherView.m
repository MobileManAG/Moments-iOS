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
//  WatcherView.m
//  moments
//
//  Created by MobileMan GmbH on 06/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "WatcherView.h"
#import "fe_defines.h"
#import "User.h"
#import "UIImageView+Haneke.h"

@implementation WatcherView

- (id)initWithFrame:(CGRect)frame user:(User*)user {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.user = user;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:STREAM_METADATA_COMMENT_LIFETIME target:self selector:@selector(onTimer) userInfo:nil repeats:NO];
        
        CGFloat size = USER_THUMBNAIL_SIZE;
        
        self.userImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
        self.userImageView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        self.userImageView.layer.cornerRadius = size/2;
        self.userImageView.clipsToBounds = YES;
        self.userImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.userImageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"thumbnail"];
        [self addSubview:self.userImageView];
        
        self.userImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addConstraints:[NSLayoutConstraint
                              constraintsWithVisualFormat:@"H:|-16.0-[_userImageView(48.0)]|"
                              options:NSLayoutFormatAlignAllLeft
                              metrics:nil views:NSDictionaryOfVariableBindings(_userImageView)]];
        [self addConstraints:[NSLayoutConstraint
                              constraintsWithVisualFormat:@"V:|-12.0-[_userImageView(48.0)]-12.0-|"
                              options:NSLayoutFormatAlignAllLeft
                              metrics:nil views:NSDictionaryOfVariableBindings(_userImageView)]];
        
        if (self.user != nil) {
            NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",@"https://graph.facebook.com/",self.user.facebookID,@"/picture?type=large"]];
            [self.userImageView hnk_setImageFromURL:imageUrl];
        }
    }
    return self;
}

-(void)onTimer
{
    [self.delegate didReachLifetimeWatcherView:self];
}

@end
