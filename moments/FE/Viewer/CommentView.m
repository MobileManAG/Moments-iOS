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
//  CommentView.m
//  moments
//
//  Created by MobileMan GmbH on 06/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "CommentView.h"
#import "fe_defines.h"
#import "User.h"
#import "UIImageView+Haneke.h"

@implementation CommentView

- (id)initWithFrame:(CGRect)frame comment:(Comment*)comment {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.comment = comment;
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:STREAM_METADATA_COMMENT_LIFETIME target:self selector:@selector(onTimer) userInfo:nil repeats:NO];
        
        CGFloat size = 32;
        
        //self.backgroundColor = [UIColor greenColor];
        
        self.labelBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        self.labelBackgroundView.backgroundColor = MOMENTS_COLOR_GREY;
        [self addSubview:self.labelBackgroundView];
        
        self.commentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.commentLabel.font = MOMENTS_FONT_CAPTION;
        self.commentLabel.textColor = [UIColor whiteColor];
        self.commentLabel.textAlignment = NSTextAlignmentLeft;
        //self.commentLabel.backgroundColor = MOMENTS_COLOR_RED;
        self.commentLabel.numberOfLines = 0;
        [self addSubview:self.commentLabel];
        
        self.userImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
        self.userImageView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        self.userImageView.layer.cornerRadius = size/2;
        self.userImageView.clipsToBounds = YES;
        self.userImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.userImageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"thumbnail"];
        [self addSubview:self.userImageView];
        
        if (self.comment != nil) {
            NSString *commentAuthor;
            NSString *commentText = @"";
            User *user = self.comment.author;
            if (user != nil) {
                NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",@"https://graph.facebook.com/",user.facebookID,@"/picture?type=large"]];
                [self.userImageView hnk_setImageFromURL:imageUrl];
                commentAuthor = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
            }
            
            switch (comment.type) {
                case kStreamEventTypeComment:
                    commentText = self.comment.text;
                    break;
                case kStreamEventTypeJoin:
                    commentAuthor = [NSString stringWithFormat:@"%@ has joined" , commentAuthor];
                    break;
                case kStreamEventTypeLeave:
                    commentAuthor = [NSString stringWithFormat:@"%@ has left" , commentAuthor];
                    break;
                default:
                    break;
            }
            
            
            
            NSMutableParagraphStyle *styleCommentLabel = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            [styleCommentLabel setAlignment:NSTextAlignmentLeft];
            [styleCommentLabel setLineBreakMode:NSLineBreakByWordWrapping];
            
            //NSTextAttachment *textAttachment01 = [[NSTextAttachment alloc] init];
            //textAttachment01.bounds = CGRectMake(0, 0, 80, 16);
            NSTextAttachment *textAttachment02 = [[NSTextAttachment alloc] init];
            textAttachment02.bounds = CGRectMake(0, 0, 10, 10);
            NSTextAttachment *textAttachment03 = [[NSTextAttachment alloc] init];
            textAttachment03.bounds = CGRectMake(0, 0, 10, 10);
            
            NSDictionary *dict1 = @{NSFontAttributeName:MOMENTS_FONT_SUBHEAD_1,//MOMENTS_FONT_CAPTION_BOLD,
                                    NSForegroundColorAttributeName:MOMENTS_COLOR_BLUE,
                                    NSParagraphStyleAttributeName:styleCommentLabel};
            NSDictionary *dict2 = @{NSFontAttributeName:MOMENTS_FONT_SUBHEAD_2,//MOMENTS_FONT_CAPTION,
                                    NSForegroundColorAttributeName:MOMENTS_COLOR_WHITE,
                                    NSParagraphStyleAttributeName:styleCommentLabel};
            
            NSMutableAttributedString *commentString = [[NSMutableAttributedString alloc] init];
            
            //[commentString appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment01]];
            [commentString appendAttributedString:[[NSAttributedString alloc] initWithString:commentAuthor attributes:dict1]];
            if (commentText.length > 0) {
                [commentString appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment02]];
                [commentString appendAttributedString:[[NSAttributedString alloc] initWithString:commentText attributes:dict2]];
            }
            [commentString appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment03]];
            
            self.commentLabel.attributedText = commentString;
            
            CGFloat commentLabelMaxWidth = self.frame.size.width - (18 + size + 18) - 5;
            CGRect paragraphRect = [commentString boundingRectWithSize:CGSizeMake(commentLabelMaxWidth, CGFLOAT_MAX)
                                         options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                         context:nil];
            CGRect commentLabelRect = CGRectMake((18 + size + 18), 10, paragraphRect.size.width, ceil(paragraphRect.size.height));
            self.commentLabel.frame = commentLabelRect;
            
            CGFloat commentLabelHeight = commentLabelRect.size.height;
            if (commentLabelHeight < 24) {
                commentLabelHeight = 24;
                commentLabelRect.size.height = commentLabelHeight;
                self.commentLabel.frame = commentLabelRect;
            }
            
            CGRect viewFrame = self.frame;
            viewFrame.size.height = 10 + commentLabelHeight + 10;
            self.frame = viewFrame;
            
            CGRect imageViewFrame = self.userImageView.frame;
            imageViewFrame.origin.x = 18;
            imageViewFrame.origin.y = viewFrame.size.height/2 - imageViewFrame.size.height/2;
            self.userImageView.frame = imageViewFrame;
            
            
            CGRect labelBackgroundRect = CGRectMake(0, commentLabelRect.origin.y, commentLabelRect.size.width + 18 + size + 18, commentLabelRect.size.height+1);
            self.labelBackgroundView.frame = labelBackgroundRect;
            
        }
    }
    return self;
}

-(void)onTimer
{
    if ([self.delegate respondsToSelector:@selector(didReachLifetimeCommentView:)]) {
        [self.delegate didReachLifetimeCommentView:self];
    }
}

@end
