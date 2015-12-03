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
//  ViewerViewController.h
//  moments
//
//  Created by MobileMan GmbH on 13/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "User.h"
#import "Stream.h"
#import "StreamService.h"
#import "StatusLabel.h"
#import "CommentView.h"

@protocol ViewerViewControllerDelegate
- (void) didCloseViewer;
@end

@class AVPlayer;
@class AVPlayerView;

@interface ViewerViewController : UIViewController <StreamServiceDelegate, CommentViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) id<StreamService> streamService;
@property (strong) StreamMetadata * streamMetadata;
@property (nonatomic, strong) IBOutlet UIButton *backButton;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet UIView *streamHeader;
@property (nonatomic, strong) IBOutlet UIImageView *streamUserImageView;
@property (nonatomic, strong) IBOutlet UILabel *streamUserNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *streamLocationLabel;
@property (nonatomic, strong) IBOutlet UIImageView *streamLocationIcon;
@property (nonatomic, strong) IBOutlet UITextField *commentTextField;
@property (nonatomic, strong) IBOutlet UILabel *reconnectLabel;

@property (nonatomic, strong) IBOutlet UILabel *videoBitrate;

@property (nonatomic, strong) User *user;
@property (nonatomic, strong) Stream *stream;
@property (nonatomic, strong) NSString *userUID;

@property (nonatomic, strong) AVPlayer* player;
@property (strong) AVPlayerItem* playerItem;
@property (strong) NSURL * streamUrl;
@property (assign) bool tryReconnect;
@property (nonatomic, strong) IBOutlet AVPlayerView *playbackView;

@property (nonatomic, strong) NSMutableArray *watchers;

@property (nonatomic, strong) NSMutableDictionary *comments;
@property (nonatomic, strong) NSMutableArray *commentsViews;


@property (nonatomic, strong) IBOutlet UICollectionView *watchersContainer;
@property (nonatomic, strong) IBOutlet UIView *commentsContainer;

@property (nonatomic, strong) IBOutlet UILabel *liveLabel;
@property (nonatomic, strong) IBOutlet UILabel *statusLabel;

@property bool isArchivedStream;

- (IBAction)back:(id)sender;

@end
