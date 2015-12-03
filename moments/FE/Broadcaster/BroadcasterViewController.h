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
//  BroadcasterViewController.h
//  moments
//
//  Created by MobileMan GmbH on 13/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StreamService.h"
#import "BroadcastService.h"
#import "Stream.h"
#import "StatusLabel.h"
#import "WatcherView.h"
#import "CommentView.h"
#import <FBSDKShareKit/FBSDKShareAPI.h>
#import "StreamSettingsViewController.h"

@protocol BroadcasterViewControllerDelegate
- (void) didCloseBroadcast;
@end

@interface BroadcasterViewController : UIViewController <StreamServiceDelegate, BroadcastServiceDelegate, CommentViewDelegate, FBSDKSharingDelegate, UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIActionSheetDelegate>

@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) id<StreamService> streamService;
@property (nonatomic, strong) id<BroadcastService> broadcastService;

@property (nonatomic, strong) IBOutlet UILabel *prepareBroadcastLabel;
@property (nonatomic, strong) IBOutlet UIView *streamHeader;
@property (nonatomic, strong) IBOutlet UIButton *stopBroadcastButton;
@property (nonatomic, strong) IBOutlet UIImageView *streamUserImageView;
@property (nonatomic, strong) IBOutlet UILabel *streamUserNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *streamLocationLabel;
@property (nonatomic, strong) IBOutlet UIImageView *streamLocationIcon;
@property (nonatomic, strong) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) IBOutlet UILabel *liveLabel;
@property (nonatomic, strong) IBOutlet UILabel *reconnectLabel;
@property (nonatomic, strong) NSTimer * reconnectLabelTimer;

@property (assign) SettingType showingSettingsOfType;
@property (nonatomic, strong) IBOutlet UIButton *minBitrateButton;
@property (nonatomic, strong) IBOutlet UIButton *maxBitrateButton;
@property (nonatomic, strong) IBOutlet UIButton *videoPresetButton;

@property (assign) BOOL isShowingLowBandwidth;
@property (nonatomic, strong) IBOutlet UIView *lowBandwidthView;
@property (nonatomic, strong) IBOutlet UILabel *lowBandwidthLabel;
@property (nonatomic, strong) IBOutlet UIButton *lowBandwidthStartButton;
@property (nonatomic, strong) IBOutlet UIButton *lowBandwidthCancelButton;

@property (nonatomic, strong) NSString *broadcastTitle;
@property (nonatomic, strong) Stream *stream;
@property (assign) BOOL isStreamReady;
@property (assign) BOOL isFinishingStream;

@property (nonatomic, strong) NSMutableArray *watchers;

@property (nonatomic, strong) NSMutableDictionary *comments;
@property (nonatomic, strong) NSMutableArray *commentsViews;


@property (nonatomic, strong) IBOutlet UICollectionView *watchersContainer;
@property (nonatomic, strong) IBOutlet UIView *commentsContainer;

@property (assign) BOOL isFBSharingActive;

- (IBAction)stopBroadcast:(id)sender;
- (IBAction)lowBandwidthStart:(id)sender;
- (IBAction)lowBandwidthCancel:(id)sender;
- (IBAction)minBitrate:(id)sender;
- (IBAction)maxBitrate:(id)sender;
- (IBAction)videoPreset:(id)sender;
@end
