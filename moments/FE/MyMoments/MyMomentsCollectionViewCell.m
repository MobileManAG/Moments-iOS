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
//  MyMomentsCollectionViewCell.m
//  moments
//
//  Created by MobileMan GmbH on 30/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "MyMomentsCollectionViewCell.h"
#import "UIImageView+Haneke.h"
#import "fe_defines.h"

@implementation MyMomentsCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.thumbnailImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.thumbnailImageView.clipsToBounds = YES;
        self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.thumbnailImageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"stream"];
        [self.contentView addSubview:self.thumbnailImageView];
        
        
        self.playButton = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width/2  - 56/2, frame.size.height/2  - 56/2, 56, 56)];
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"Play_56.png"] forState:UIControlStateNormal];
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"Play_56.png"] forState:UIControlStateHighlighted];
        [self.playButton addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.playButton];
        
        self.moreButton = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width - 48, 0, 48, 48)];
        [self.moreButton setBackgroundImage:[UIImage imageNamed:@"More.png"] forState:UIControlStateNormal];
        [self.moreButton setBackgroundImage:[UIImage imageNamed:@"More.png"] forState:UIControlStateHighlighted];
        [self.moreButton addTarget:self action:@selector(more:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.moreButton];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height - 50, frame.size.width, 50)];
        self.titleLabel.hidden = YES;
        self.titleLabel.backgroundColor = MOMENTS_COLOR_YELLOW_SEMITRANSPARENT;
        self.titleLabel.textColor = MOMENTS_COLOR_BLACK;
        self.titleLabel.font = MOMENTS_FONT_TITLE_2;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.titleLabel];
    }
    
    return self;
}

- (void)calculatePlayButtonPosition
{
    CGFloat cellHeight = self.frame.size.height;
    CGFloat labelHeight = 0.0;
    if (self.stream.text.length > 0) {
        labelHeight = 50.0;
    }
    CGFloat playHeight = 56.0;
    
    CGRect playButtonRect = self.playButton.frame;
    playButtonRect.origin.y = (cellHeight - labelHeight)/2 - playHeight/2;
    self.playButton.frame = playButtonRect;
}

- (void)prepareForReuse
{
    self.stream = nil;
    self.indexPath = nil;
    [self.thumbnailImageView hnk_cancelSetImage];
    self.thumbnailImageView.image = nil;
    self.titleLabel.hidden = YES;
    self.titleLabel.text = @"";
}

- (IBAction)play:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(didSelectWatchOf:)]) {
        [self.delegate didSelectWatchOf:self.stream];
    }

}

- (IBAction)more:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(didSelectMoreOn:onIndexPath:)]) {
        [self.delegate didSelectMoreOn:self.stream onIndexPath:self.indexPath];
    }
}

@end
