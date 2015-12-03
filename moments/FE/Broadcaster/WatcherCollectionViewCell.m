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
//  WatcherCollectionViewCell.m
//  moments
//
//  Created by MobileMan GmbH on 02/06/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "WatcherCollectionViewCell.h"
#import "UIImageView+Haneke.h"

@implementation WatcherCollectionViewCell

-(id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self)
    {
        CGFloat size = 32;
        
        self.thumbnailImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
        self.thumbnailImageView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        self.thumbnailImageView.layer.cornerRadius = size/2;
        self.thumbnailImageView.clipsToBounds = YES;
        self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.thumbnailImageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"thumbnail"];
        
        [self addSubview:self.thumbnailImageView];
    }
    
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.thumbnailImageView.image = nil;
}

@end
