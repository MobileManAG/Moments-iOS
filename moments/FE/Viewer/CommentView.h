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
//  CommentView.h
//  moments
//
//  Created by MobileMan GmbH on 06/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comment.h"

@class CommentView;

@protocol CommentViewDelegate
- (void)didReachLifetimeCommentView:(CommentView *)commentView;
@end

@interface CommentView : UIView

@property (nonatomic, weak) NSObject<CommentViewDelegate>* delegate;
@property (nonatomic, strong) Comment *comment;
@property (nonatomic, strong) NSTimer * timer;

@property (nonatomic, strong) UIView *labelBackgroundView;
@property (nonatomic, strong) UILabel *commentLabel;
@property (nonatomic, strong) UIImageView *userImageView;

- (id)initWithFrame:(CGRect)frame comment:(Comment*)comment;

@end