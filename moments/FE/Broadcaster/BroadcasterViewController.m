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
//  BroadcasterViewController.m
//  moments
//
//  Created by MobileMan GmbH on 13/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "BroadcasterViewController.h"

#include "AppDelegate.h"
#import "fe_defines.h"
#import "ServiceFactory.h"
#import "SignInViewController.h"
#import "BroadcastService.h"
#import "Settings.h"
#import "SettingsTransitioningDelegate.h"
#import "MomentsNavigationController.h"
#import "ViewerViewController.h"
#import "Slice.h"
#import "UserSession.h"
#import "User.h"
#import "Location.h"

#import "StreamMetadata.h"
#import "Comment.h"

#import "UIImageView+Haneke.h"

#import <FBSDKCoreKit/FBSDKAccessToken.h>
#import <FBSDKCoreKit/FBSDKGraphRequest.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnection.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKSharePhoto.h>
#import <FBSDKShareKit/FBSDKShareOpenGraphContent.h>
#import <FBSDKShareKit/FBSDKShareOpenGraphAction.h>

#import "SVProgressHUD.h"
#import "mom_notifications.h"
#import "mom_defines.h"

#import "WatcherCollectionViewCell.h"

#import "VideoUtils.h"

#define ANIMATION_DURATION 0.25

#define COMMENT_ANIMATION_DURATION 1.0
#define COMMENT_TERMINATION_ANIMATION_DURATION 0.5
#define WATCHER_ANIMATION_DURATION 1.0
#define WATCHER_TERMINATION_ANIMATION_DURATION 0.5

@implementation BroadcasterViewController

- (id) init {
    self = [super init];
    if(self){
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.broadcastService = [ServiceFactory broadcastService];
    self.broadcastService.delegate = self;
    
    self.streamService = [ServiceFactory streamService:self];

    self.title = @"Broadcaster";
    [self.navigationItem setHidesBackButton:YES];
    
    //prepare broadcast
    self.prepareBroadcastLabel.text = @"Notifying friends...";
    self.prepareBroadcastLabel.font = MOMENTS_FONT_TITLE_1;
    self.prepareBroadcastLabel.backgroundColor = MOMENTS_COLOR_YELLOW_SEMITRANSPARENT;
    
    //lowBandwidth Label
    self.lowBandwidthLabel.text = @"Bandwidth too low...";
    self.lowBandwidthLabel.font = MOMENTS_FONT_TITLE_1;
    self.lowBandwidthLabel.backgroundColor = [UIColor clearColor];
    self.lowBandwidthLabel.textColor = MOMENTS_COLOR_WHITE;
    
    //lowBandwidth Start
    self.lowBandwidthStartButton.backgroundColor = MOMENTS_COLOR_YELLOW_SEMITRANSPARENT;
    [self.lowBandwidthStartButton setTitle:@"RETRY" forState:UIControlStateNormal];
    [self.lowBandwidthStartButton setTitle:@"RETRY" forState:UIControlStateHighlighted];
    [[self.lowBandwidthStartButton titleLabel] setTextColor:MOMENTS_COLOR_WHITE];
    [[self.lowBandwidthStartButton titleLabel] setFont:MOMENTS_FONT_DISPLAY_1];
    [[self.lowBandwidthStartButton titleLabel] setTextAlignment:NSTextAlignmentCenter];
    
    //lowBandwidth Cancel
    self.lowBandwidthCancelButton.backgroundColor = MOMENTS_COLOR_BLUE;
    [self.lowBandwidthCancelButton setTitle:@"PASS" forState:UIControlStateNormal];
    [self.lowBandwidthCancelButton setTitle:@"PASS" forState:UIControlStateHighlighted];
    [[self.lowBandwidthCancelButton titleLabel] setTextColor:MOMENTS_COLOR_BLACK];
    [[self.lowBandwidthCancelButton titleLabel] setFont:MOMENTS_FONT_DISPLAY_1];
    [[self.lowBandwidthCancelButton titleLabel] setTextAlignment:NSTextAlignmentCenter];
    
    //stream user
    CGFloat size = USER_THUMBNAIL_SIZE;
    self.streamUserImageView.layer.cornerRadius = size/2;
    self.streamUserImageView.clipsToBounds = YES;
    self.streamUserImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.streamUserImageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"thumbnail"];
    
    //stream user
    self.streamUserNameLabel.font = MOMENTS_FONT_TITLE_2;
    
    //stream location
    self.streamLocationLabel.font = MOMENTS_FONT_SUBHEAD_2;
    
    self.streamUserNameLabel.text = @"";
    self.streamLocationLabel.text = @"";
    self.streamLocationIcon.hidden = YES;
    
    //live label
    self.liveLabel.font = MOMENTS_FONT_SUBHEAD_1;
    [self setLiveLabelText:@"LIVE"];
    
    //stream status
    [self updateStatus:0];
    
    //reconnect label
    NSMutableParagraphStyle *styleStatus = [NSMutableParagraphStyle new];
    styleStatus.lineBreakMode = NSLineBreakByWordWrapping;
    styleStatus.alignment = NSTextAlignmentLeft;
    
    NSTextAttachment *textAttachment01 = [[NSTextAttachment alloc] init];
    textAttachment01.bounds = CGRectMake(0, 0, 16, 16);
    NSTextAttachment *textAttachment02 = [[NSTextAttachment alloc] init];
    textAttachment02.bounds = CGRectMake(0, 0, 16, 16);
    
    NSDictionary *dict = @{NSFontAttributeName:MOMENTS_FONT_SUBHEAD_1,
                            NSParagraphStyleAttributeName:styleStatus};
    
    NSMutableAttributedString *statusString = [[NSMutableAttributedString alloc] init];
    [statusString appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment01]];
    [statusString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Trying to reconnect..." attributes:dict]];
    [statusString appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment02]];
    [self.reconnectLabel setAttributedText:statusString];
    
    //watchers & comments
    self.watchers = [[NSMutableArray alloc] init];
    self.comments = [[NSMutableDictionary alloc] init];
    self.commentsViews = [[NSMutableArray alloc] init];
    
    //watchersContainer
    self.watchersContainer.clipsToBounds = YES;
    
    //commentsContainer
    self.commentsContainer.clipsToBounds = YES;
    
    //double tap
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapGesture];
    
    //starting broadcast
    [self.broadcastService startBroadcasting:self.broadcastTitle location:nil];
    //[self showTestEvents];
    
    self.showingSettingsOfType = kSettingTypeUnknown;
    [self updateMinBitrateButton];
    [self updateMaxBitrateButton];
    [self updateVideoPresetButton];
}

- (void) viewDidUnload
{
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void) setLiveLabelText:(NSString*)text
{
    NSMutableParagraphStyle *styleLiveLabel = [NSMutableParagraphStyle new];
    styleLiveLabel.lineBreakMode = NSLineBreakByWordWrapping;
    styleLiveLabel.alignment = NSTextAlignmentLeft;
    
    NSTextAttachment *textAttachmentLiveLabel = [[NSTextAttachment alloc] init];
    textAttachmentLiveLabel.bounds = CGRectMake(0, 0, 16, 16);
    
    NSDictionary *dictLiveLabel = @{NSFontAttributeName:MOMENTS_FONT_SUBHEAD_1,
                                    NSParagraphStyleAttributeName:styleLiveLabel};
    
    NSMutableAttributedString *liveLabelString = [[NSMutableAttributedString alloc] init];
    [liveLabelString appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachmentLiveLabel]];
    [liveLabelString appendAttributedString:[[NSAttributedString alloc] initWithString:text attributes:dictLiveLabel]];
    [liveLabelString appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachmentLiveLabel]];
    [self.liveLabel setAttributedText:liveLabelString];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updateStreamHeader
{
    //user name
    UserSession *userSession = [[ServiceFactory userService] currentSession];
    self.streamUserNameLabel.text = [NSString stringWithFormat:@"%@ %@", userSession.user.firstName, userSession.user.lastName];
    self.streamLocationIcon.hidden = NO;
    
    //user image
    NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",@"https://graph.facebook.com/",userSession.user.facebookID,@"/picture?type=large"]];
    [self.streamUserImageView hnk_setImageFromURL:imageUrl];
    
    //location
    [self updateStreamLocation];
}

- (void) updateStreamLocation
{
    NSString *locationString = [self getStreamLocationString];
    
    if (locationString.length == 0) {
        locationString = @"Somewhere";
    }
    
    self.streamLocationLabel.text = locationString;
}

- (NSString*) getStreamLocationString {
    
    NSString *locationString = @"";
    NSString *locationItem = @"";
    
    if (self.stream) {
        if (self.stream.location) {
            
            locationItem = self.stream.location.city;
            
            if (locationItem.length > 0) {
                locationString = locationItem;
            }
            
            locationItem = self.stream.location.country;
            
            if (locationItem.length > 0) {
                if (locationString.length > 0) {
                    locationString = [NSString stringWithFormat:@"%@, %@", locationString, locationItem];
                } else {
                    locationString = [NSString stringWithFormat:@"%@", locationItem];
                }
                
            }
            /*
            locationItem = self.stream.location.state;
            
            if (locationItem.length > 0) {
                locationString = [NSString stringWithFormat:@"%@, %@", locationString, locationItem];
            }*/
        }
    }
    
    if (locationString.length == 0) {
        locationString = @"Somewhere";
    }
    
    return locationString;
}

- (NSString*) getStreamTitleString {
    NSString *result = @""; 
    
    result = self.stream.text;
    if (result.length == 0) {
        result = @"";
    }
    
    return result;
}

- (IBAction)stopBroadcast:(id)sender
{
    NSLog(@"didPushStopBroadcastButton");
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:@"Are you sure you want to end the moment?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch(buttonIndex) {
        case 0: //"No" pressed
            break;
        case 1: //"Yes" pressed
            [self stopBroadcastConfirmed];
            break;
    }
}

- (void) stopBroadcastConfirmed {
    
    [self.streamService leaveBroadcast:self.stream success:^(StreamMetadata *metadata) {
        NSLog(@"leaveBroadcast success");
    } failure:^(NSError *error) {
        NSLog(@"leaveBroadcast failure");
    }];
    
    [self.broadcastService stopBroadcasting];
    self.prepareBroadcastLabel.text = @"Finishing broadcast...";
    self.reconnectLabel.hidden = YES;
    [self hideStream];
    self.isFinishingStream = YES;
}

- (IBAction)lowBandwidthStart:(id)sender;
{
    [self hideLowBandwidth];
}

- (IBAction)lowBandwidthCancel:(id)sender
{
    [self hideLowBandwidth];
    [self stopBroadcastConfirmed];
}

#pragma mark BroadcastServiceDelegate

- (void) showStream
{
    [self updateStreamHeader];
    
    self.prepareBroadcastLabel.hidden = YES;
    self.streamHeader.hidden = NO;
    self.statusLabel.hidden = NO;
    self.liveLabel.hidden = NO;
    self.commentsContainer.hidden = NO;
    self.watchersContainer.hidden = NO;
    
    [((AppDelegate *)[UIApplication sharedApplication].delegate) didStartBroadcast];
}

- (void) hideStream
{
    self.prepareBroadcastLabel.hidden = NO;
    self.streamHeader.hidden = YES;
    self.statusLabel.hidden = YES;
    self.liveLabel.hidden = YES;
    self.commentsContainer.hidden = YES;
    self.watchersContainer.hidden = YES;
    self.reconnectLabel.hidden = YES;
    
    [((AppDelegate *)[UIApplication sharedApplication].delegate) didStopBroadcast];
}

- (void) showLowBandwidth
{
    [self hideStream];
    self.prepareBroadcastLabel.hidden = YES;
    self.lowBandwidthView.hidden = NO;
    self.isShowingLowBandwidth = YES;
    self.reconnectLabel.hidden = YES;
}

- (void) hideLowBandwidth
{
    self.lowBandwidthView.hidden = YES;
    if (self.isStreamReady) {
        [self showStream];
    } else {
        [self hideStream];
    }
     self.isShowingLowBandwidth = NO;
}

- (void)broadcastService:(id<BroadcastService>)service didStopRunningWithError:(NSError *)error
{
    NSLog(@"");
}

- (void)broadcastService:(id<BroadcastService>)service didFinishFile:(NSString *)fileName {
    
}

- (void)broadcastService:(id<BroadcastService>)service streamReady:(Stream *)stream {
    
    self.isStreamReady = YES;
    
    [self.streamService joinBroadcast:stream success:^(StreamMetadata *metadata) {
        NSLog(@"joinBroadcast success");
    } failure:^(NSError *error) {
        NSLog(@"joinBroadcast failure");
    }];
    
    [self updateStreamHeader];
}

- (void)broadcastService:(id<BroadcastService>)service didStartStreaming:(Stream *)stream {
    
    if (self.isFBSharingActive) {
        
        NSString *streamTitle = @"";
        if (self.stream.text != nil && self.stream.text.length > 0) {
            streamTitle = self.stream.text;
        }
        
        NSDictionary *params = @{@"other": self.stream.videoSharingUrl,
                                 @"fb:explicitly_shared": @"true"
                                 };
        
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/momentsbuzz:live_broadcast" parameters: params HTTPMethod:@"POST"]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             if (!error) {
                 NSLog(@"Post id:%@", result[@"id"]);
             } else {
                 NSLog(@"FB Post error:%@", error);
             }
         }];
    }
}

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
    NSLog(@"");
}
- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
    NSLog(@"");
}
- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
    NSLog(@"");
}

- (void)broadcastServiceDidStartBroadcasting:(id<BroadcastService>)service stream:(Stream *)stream
{
    self.stream = stream;
    
    if (!self.isShowingLowBandwidth) {
        [self showStream];
    }
}

- (BOOL)bandwith:(double)first isLessThen:(double)second {
    
    if(first < second)
        return YES;
    else
        return NO;
}

- (void)broadcastService:(id<BroadcastService>)service didDetermineBandwidth:(double)bandwith calculatedBitrate:(double)calculatedBitrate {
    
    if ([self bandwith:bandwith isLessThen:MINIMUM_BANDWITH_FOR_BROADCAST]) {
        
        if (!self.isFinishingStream) {
            [self showLowBandwidth];
        }
    }
}

- (void)broadcastServiceDidStopBroadcasting:(id<BroadcastService>)service stream:(Stream *)stream
{
    self.stream = nil;
    [((AppDelegate *)[UIApplication sharedApplication].delegate) didStopBroadcast];
    [self.delegate didCloseBroadcast];
    [self.navigationController popViewControllerAnimated:YES];
    
}
- (void)broadcastService:(id<BroadcastService>)service didStopBroadcastingWithError:(NSError *)error
{
    self.stream = nil;
    
    NSDictionary *userInfo = error.userInfo;
    NSString *localizedDescription = [userInfo objectForKey:@"NSLocalizedDescription"];
    NSString *message = [NSString stringWithFormat:@"%@", localizedDescription];
    [SVProgressHUD setBackgroundColor:MOMENTS_COLOR_RED];
    [SVProgressHUD setForegroundColor:MOMENTS_COLOR_WHITE];
    [SVProgressHUD setFont:MOMENTS_FONT_TITLE_1];
    [SVProgressHUD setCornerRadius:0.0];
    [SVProgressHUD showStatus:message];
    [((AppDelegate *)[UIApplication sharedApplication].delegate) didStopBroadcast];
    [self.delegate didCloseBroadcast];
    [self.navigationController popViewControllerAnimated:YES];
}

- (bool)broadcastServiceUploadWideThumbnail:(id<BroadcastService>)service {
    return self.isFBSharingActive;
}

- (UIImage *)drawFacebookThumbnailWithBackgroundImage:(UIImage*)backgroundImage userImage:(UIImage*)userImage {
    UIImage *result = nil;
    /*
    User *myUser;
    NSString *userName = @"";
    UserSession *userSession = [[ServiceFactory userService] currentSession];
    if (userSession != nil) {
        myUser = userSession.user;
        userName = [NSString stringWithFormat:@"%@ %@", myUser.firstName, myUser.lastName];
    }
    */
    CGSize size = CGSizeMake(1200, 630);
    UIGraphicsBeginImageContext(size);
    
    //background
    if (backgroundImage) {
        
        CGSize backgroundImageSize = backgroundImage.size;
        
        CGFloat xOffset = 0;
        
        
        CGFloat ratio = size.width/backgroundImageSize.width;
        CGFloat newWidth = size.width;
        CGFloat newHeight = size.height * ratio;
        
        CGFloat yOffset = size.height/2 - newHeight/2;
        
        CGRect backgroundImageRect = CGRectMake(xOffset, yOffset, newWidth, newHeight);
        [backgroundImage drawInRect:backgroundImageRect];
        
        
    }
    
    //blue overlay
    CGRect overlayRect = CGRectMake(0, 0, size.width, size.height);
    
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: overlayRect];
    [rectanglePath closePath];
    [MOMENTS_COLOR_BLUE_SEMITRANSPARENT set];
    [rectanglePath fill];
    
    //replay
    UIBezierPath *aPath = [UIBezierPath bezierPath];
    [aPath moveToPoint:CGPointMake(0, 20)];
    [aPath addLineToPoint:CGPointMake(92, 20)];
    [aPath addLineToPoint:CGPointMake(92, 70)];
    [aPath addLineToPoint:CGPointMake(0, 70)];
    [aPath addLineToPoint:CGPointMake(0, 20)];
    [aPath closePath];
    [MOMENTS_COLOR_RED_SEMITRANSPARENT set];
    [aPath fill];
    
    CGRect replayLabelRect = CGRectMake(10, 18, 120, 60);
    NSString* replayLabel = @"LIVE";
    NSMutableParagraphStyle *paragraphStyleForReplayeLabel = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyleForReplayeLabel.alignment = NSTextAlignmentLeft;
    NSDictionary *attributesForReplayLabel = @{ NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Semibold" size:38],
                                                  NSParagraphStyleAttributeName: paragraphStyleForReplayeLabel,
                                                  NSForegroundColorAttributeName: MOMENTS_COLOR_WHITE};
    [replayLabel drawInRect:replayLabelRect withAttributes:attributesForReplayLabel];
    
    //moments logo
    UIImage *logoImage = [UIImage imageNamed:@"moments.png"];
    CGRect logoImageRect = CGRectMake(450, 20, 300, 61);
    [logoImage drawInRect:logoImageRect];
 
    
    //watch button
    CGRect watchRect = CGRectMake(0, 260, size.width, 110);
    UIBezierPath* watchRectPath = [UIBezierPath bezierPathWithRect: watchRect];
    [watchRectPath closePath];
    [MOMENTS_COLOR_YELLOW_SEMITRANSPARENT set];
    [watchRectPath fill];
    
    CGRect watchLabelRect = CGRectMake(5, 278 , size.width, 100);
    NSString* label = @"WATCH";
    
    if (self.stream.text.length > 0) {
        label  = self.stream.text;
    }
    
    NSMutableParagraphStyle *paragraphStyleForWatchLabel = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyleForWatchLabel.alignment = NSTextAlignmentCenter;
    NSDictionary *attributesForWatchLabel = @{ NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Semibold" size:60],
                                                  NSParagraphStyleAttributeName: paragraphStyleForWatchLabel,
                                                  NSForegroundColorAttributeName: MOMENTS_COLOR_BLACK};
    [label drawInRect:watchLabelRect withAttributes:attributesForWatchLabel];
    
    result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

- (UIImage *)broadcastService:(id<BroadcastService>)service createWideThumbnail:(UIImage *)thumbnail {
    
    UIImage *result = nil;
    
    result = [self drawFacebookThumbnailWithBackgroundImage:thumbnail userImage:nil];
    
    return result;
}

- (void)broadcastService:(id<BroadcastService>)service didUploadThumbnail:(NSString *)url ofType:(NSString *)ofType
{
    if ([ofType isEqualToString:THUMBNAIL_WIDE]) {
        
    }
}


- (void) showReconnectLabel
{
    if (!self.isFinishingStream && self.isStreamReady) {
        self.reconnectLabelTimer = [NSTimer scheduledTimerWithTimeInterval:BROADCASTER_RECONNECT_LABEL_LIFETIME target:self selector:@selector(hideReconnectLabel) userInfo:nil repeats:NO];
    
        self.reconnectLabel.hidden = NO;
    }
}

- (void) hideReconnectLabel
{
    self.reconnectLabel.hidden = YES;
}

- (void)broadcastServiceDidDetectSegmentsDrops:(id<BroadcastService>)service
{
    [self showReconnectLabel];
}

- (void)broadcastServiceDidDetectSegmentDrop:(id<BroadcastService>)service
{
    [self showReconnectLabel];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.watchers.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    WatcherCollectionViewCell *watcherCollectionViewCell = nil;
    
    static NSString *cellIdentifier = @"WatcherCollectionViewCell";
    watcherCollectionViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (watcherCollectionViewCell == nil) {
        watcherCollectionViewCell = [[WatcherCollectionViewCell alloc] init];
    }
   
    User *watcher = [self.watchers objectAtIndex:row];
    if (watcher) {
        NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",@"https://graph.facebook.com/",watcher.facebookID,@"/picture?type=large"]];
        [watcherCollectionViewCell.thumbnailImageView hnk_setImageFromURL:imageUrl];
    }
    
    return watcherCollectionViewCell;
}

#pragma mark StreamServiceDelegate

- (void)updateStatus:(int)watcherCount {
    
    NSMutableParagraphStyle *styleStatus = [NSMutableParagraphStyle new];
    styleStatus.lineBreakMode = NSLineBreakByWordWrapping;
    styleStatus.alignment = NSTextAlignmentLeft;
    
    NSTextAttachment *textAttachment01 = [[NSTextAttachment alloc] init];
    textAttachment01.bounds = CGRectMake(0, 0, 16, 16);
    NSTextAttachment *textAttachment02 = [[NSTextAttachment alloc] init];
    textAttachment02.bounds = CGRectMake(0, 0, 16, 16);
    
    NSDictionary *dict1 = @{NSFontAttributeName:MOMENTS_FONT_SUBHEAD_1,
                            NSParagraphStyleAttributeName:styleStatus};
    NSDictionary *dict2 = @{NSFontAttributeName:MOMENTS_FONT_SUBHEAD_2,
                            NSParagraphStyleAttributeName:styleStatus};
    NSDictionary *dict3 = @{NSFontAttributeName:MOMENTS_FONT_SUBHEAD_1,
                            NSParagraphStyleAttributeName:styleStatus};
    
    NSMutableAttributedString *statusString = [[NSMutableAttributedString alloc] init];
    [statusString appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment01]];
    [statusString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d ", watcherCount] attributes:dict1]];
    [statusString appendAttributedString:[[NSAttributedString alloc] initWithString:@"watching " attributes:dict2]];
    [statusString appendAttributedString:[[NSAttributedString alloc] initWithString:[self getStreamTitleString] attributes:dict3]];
    [statusString appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment02]];
    [self.statusLabel setAttributedText:statusString];
}

- (CommentView*) viewForComment:(Comment*)comment yOffset:(CGFloat)yOffset
{
    CommentView *result = nil;
    
    CGFloat y = self.commentsContainer.frame.size.height + yOffset;
    CGFloat commentViewWidth = self.view.bounds.size.width;
    result = [[CommentView alloc] initWithFrame:CGRectMake(0, y, commentViewWidth, 72) comment:comment];
    result.delegate = self;
    [self.commentsContainer addSubview:result];
    
    return result;
}

- (BOOL) isNewComment:(Comment*)comment
{
    BOOL result = YES;
    NSNull *object = [self.comments objectForKey:comment.uuid];
    if (object != nil) {
        return NO;
    }
    
    return result;
}

- (void) handleMetadataComments:(NSMutableArray*)newComments
{
    CGFloat yOffset = 0;
    
    for (int i=0; i < newComments.count; i++) {
        Comment *comment = [newComments objectAtIndex:i];
        CommentView *commentView = [self viewForComment:comment yOffset:yOffset];
        [self.commentsViews addObject:commentView];
        yOffset += commentView.frame.size.height;
    }
    
    int commentsToTerminateCount = (int)self.commentsViews.count - STREAM_METADATA_COMMENTS_MAX_COUNT;
    for (int i=0; i < commentsToTerminateCount; i++) {
        CommentView *commentView = [self.commentsViews objectAtIndex:i];
        [self didReachLifetimeCommentView:commentView];
    }
    
    for (int i=0; i < self.commentsViews.count; i++) {
        
        CommentView *commentView = [self.commentsViews objectAtIndex:i];
        CGRect commentViewFrame = commentView.frame;
        //NSLog(@"%f", commentViewFrame.origin.y);
        CGFloat newYOffset = commentViewFrame.origin.y - yOffset;
        //NSLog(@"view: %i, oldY: %f, newY: %f", i, commentViewFrame.origin.y, newYOffset);
        
        [UIView beginAnimations: @"animDown" context: nil];
        [UIView setAnimationBeginsFromCurrentState: YES];
        [UIView setAnimationDuration: COMMENT_ANIMATION_DURATION];
        
        commentViewFrame.origin.y = newYOffset;
        commentView.frame = commentViewFrame;
        [UIView commitAnimations];
    }
}


- (User*)getUserWithId:(NSString*)userUID fromComments:(NSArray*)events
{
    User *result = nil;
    
    for (int i=0; i < events.count; i++) {
        Comment *comment = [events objectAtIndex:i];
        User *user = comment.author;
        if ([userUID isEqualToString:user.uuid]) {
            return user;
        }
    }
    
    return result;
}

- (void) handleMetadataEvents:(NSArray*)eventsArray {
    
    NSMutableArray *newComments = [[NSMutableArray alloc] init];
    NSMutableDictionary *watchersToAddRemove = [[NSMutableDictionary alloc] init];
    
    for (int i=0; i < eventsArray.count; i++) {
        Comment *comment = [eventsArray objectAtIndex:i];
        
        if ([self isNewComment:comment]) {
            if (comment.type != kStreamEventTypeLeave) {
                [newComments addObject:comment];
                [self.comments setObject:[NSNull null] forKey:comment.uuid];
            }
        }
        
        if (comment.type == kStreamEventTypeComment) {
            
        } else if (comment.type == kStreamEventTypeJoin) {
            
            NSNumber *number = [watchersToAddRemove objectForKey:comment.author.uuid];
            int newNumber;
            if (number != nil) {
                newNumber = [number intValue] +1;
            } else {
                newNumber = 1;
            }
            
            [watchersToAddRemove setObject:[NSNumber numberWithInt:newNumber] forKey:comment.author.uuid];
            
        } else if (comment.type == kStreamEventTypeLeave) {
            
            NSNumber *number = [watchersToAddRemove objectForKey:comment.author.uuid];
            int newNumber;
            if (number != nil) {
                newNumber = [number intValue] -1;
            } else {
                newNumber = -1;
            }
            
            [watchersToAddRemove setObject:[NSNumber numberWithInt:newNumber] forKey:comment.author.uuid];
        }
        
    }
    
    if (newComments.count > 0) {
        [self handleMetadataComments:newComments];
    }
    
    NSMutableArray *watchersToAdd = [[NSMutableArray alloc] init];
    NSMutableDictionary *watchersToRemove = [[NSMutableDictionary alloc] init];
    
    for (NSString* key in watchersToAddRemove) {
        NSNumber *number = [watchersToAddRemove objectForKey:key];
        int numberInt = [number intValue];
        
        if (numberInt > 0) {
            
            User *user = [self getUserWithId:key fromComments:eventsArray];
            if (user) {
                [watchersToAdd addObject:user];
            }
            
        } else if (numberInt < 0) {
            
            User *user = [self getUserWithId:key fromComments:eventsArray];
            if (user) {
                [watchersToRemove setObject:user forKey:user.uuid];
            }
        }
    }
    
    NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
    NSMutableArray *watchersTodelete = [[NSMutableArray alloc] init];
    for (int i=0; i < self.watchers.count; i++) {
        User *user = [self.watchers objectAtIndex:i];
        User *userToRemove = [watchersToRemove objectForKey:user.uuid];
        if (userToRemove != nil) {
            [watchersTodelete addObject:userToRemove];
            [indexPathsToDelete addObject:[NSIndexPath indexPathForItem:i inSection:0]];
        }
    }
    for (int i=0; i < watchersTodelete.count; i++) {
        User *user = [watchersTodelete objectAtIndex:i];
        [self.watchers removeObject:user];
    }
    
    NSMutableArray *indexPathsToInsert = [[NSMutableArray alloc] init];
    for (int i=0; i < watchersToAdd.count; i++) {
        User *user = [watchersToAdd objectAtIndex:i];
        [self.watchers insertObject:user atIndex:0];
        [indexPathsToInsert addObject:[NSIndexPath indexPathForItem:i inSection:0]];
    }
    
    [self.watchersContainer performBatchUpdates:^{
        [self.watchersContainer deleteItemsAtIndexPaths:indexPathsToDelete];
        [self.watchersContainer insertItemsAtIndexPaths:indexPathsToInsert];
    } completion:^(BOOL finished) {
        NSLog(@"");
    }];
    
    NSLog(@"");
}

- (void)streamService:(id<StreamService>)service didReceiveStreamMetadadata:(StreamMetadata*)metadata
{
    //NSLog(@"didReceiveStreamMetadadata");
    
    [self updateStatus:metadata.watchersCount];
    
    NSArray *sortedEvents = [metadata.events sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        long long first = [(Comment*)obj1 timestamp];
        long long second = [(Comment*)obj2 timestamp];
        return first > second;
    }];
    [self handleMetadataEvents:sortedEvents];
}

- (void)streamService:(id<StreamService>)service streamMetadadataFetchFailed:(NSError*)error {
    NSLog(@"streamMetadadataFetchFailed");
}

- (void)streamService:(id<StreamService>)service didUpdateStreamLocation:(Location *)location
{
    [self updateStreamLocation];
    NSLog(@"didUpdateStreamLocation");
}

#pragma mark CommentViewDelegate

- (void)didReachLifetimeCommentView:(CommentView *)commentView
{
    //animated termination
    [UIView animateWithDuration:COMMENT_TERMINATION_ANIMATION_DURATION animations:^{
        commentView.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        
        [commentView removeFromSuperview];
        //[self.commentsViews removeObject:commentView];
    }];
}

#pragma mark change camera

- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    
    //[self updateTestEvents];
    
    if (sender.state == UIGestureRecognizerStateRecognized) {
        [self.broadcastService switchCamera:^(NSError *error) {
            NSLog(@"");
        }];
    }
}

- (void) updateMinBitrateButton {
    
    NSString *minBitrate = [NSString stringWithFormat:@"%.0f", [VideoUtils minBitrate]/1000];
    [self.minBitrateButton setTitle:[NSString stringWithFormat:@"Min: %@ kb/s", minBitrate] forState:UIControlStateNormal];
    [self.minBitrateButton setTitle:[NSString stringWithFormat:@"Min: %@ kb/s", minBitrate] forState:UIControlStateHighlighted];
}
- (void) updateMaxBitrateButton {
    
    NSString *maxBitrate = [NSString stringWithFormat:@"%.0f", [VideoUtils maxBitrate]/1000];
    [self.maxBitrateButton setTitle:[NSString stringWithFormat:@"Max: %@ kb/s", maxBitrate] forState:UIControlStateNormal];
    [self.maxBitrateButton setTitle:[NSString stringWithFormat:@"Max: %@ kb/s", maxBitrate] forState:UIControlStateHighlighted];
}
- (void) updateVideoPresetButton {
    
    NSString *videoSessionPreset = [VideoUtils videoSessionPreset];
    NSString *videoSessionPresetLabelString = @"";
    
    if ([videoSessionPreset isEqualToString:AVCaptureSessionPresetLow]) {
        videoSessionPresetLabelString = @"Low";
    } else if ([videoSessionPreset isEqualToString:AVCaptureSessionPresetMedium]) {
        videoSessionPresetLabelString = @"Medium";
    } else if ([videoSessionPreset isEqualToString:AVCaptureSessionPresetHigh]) {
        videoSessionPresetLabelString = @"High";
    } else if ([videoSessionPreset isEqualToString:AVCaptureSessionPreset352x288]) {
        videoSessionPresetLabelString = @"CIF";
    } else if ([videoSessionPreset isEqualToString:AVCaptureSessionPreset640x480]) {
        videoSessionPresetLabelString = @"VGA";
    } else if ([videoSessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
        videoSessionPresetLabelString = @"720p";
    } else if ([videoSessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        videoSessionPresetLabelString = @"1080p";
    } else if ([videoSessionPreset isEqualToString:VIDEO_PRESET_AUTO]) {
        videoSessionPresetLabelString = @"Automatic";
    } else {
        videoSessionPresetLabelString = @"Automatic";
    }

    [self.videoPresetButton setTitle:[NSString stringWithFormat:@"%@", videoSessionPresetLabelString] forState:UIControlStateNormal];
    [self.videoPresetButton setTitle:[NSString stringWithFormat:@"%@", videoSessionPresetLabelString] forState:UIControlStateHighlighted];
}

- (IBAction)minBitrate:(id)sender
{
    self.showingSettingsOfType = kSettingTypeMinBitrate;
    
    NSString *title = @"Minimal bitrate";
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                              delegate:self
                                     cancelButtonTitle:nil
                                destructiveButtonTitle:nil
                                     otherButtonTitles:nil];
    
    double maxBitrate = [VideoUtils maxBitrate];
    
    [actionSheet addButtonWithTitle:@"bitrate100"];
    if (maxBitrate >= 200*1000) {
        [actionSheet addButtonWithTitle:@"bitrate200"];
    }
    if (maxBitrate >= 300*1000) {
        [actionSheet addButtonWithTitle:@"bitrate300"];
    }
    if (maxBitrate >= 400*1000) {
        [actionSheet addButtonWithTitle:@"bitrate400"];
    }
    if (maxBitrate >= 500*1000) {
        [actionSheet addButtonWithTitle:@"bitrate500"];
    }
    if (maxBitrate >= 600*1000) {
        [actionSheet addButtonWithTitle:@"bitrate600"];
    }
    if (maxBitrate >= 700*1000) {
        [actionSheet addButtonWithTitle:@"bitrate700"];
    }
    if (maxBitrate >= 800*1000) {
        [actionSheet addButtonWithTitle:@"bitrate800"];
    }
    [actionSheet showInView:self.view];
}

- (IBAction)maxBitrate:(id)sender
{
    self.showingSettingsOfType = kSettingTypeMaxBitrate;
    
    NSString *title = @"Maximal bitrate";
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                              delegate:self
                                     cancelButtonTitle:nil
                                destructiveButtonTitle:nil
                                     otherButtonTitles:nil];
    
    double minBitrate = [VideoUtils minBitrate];
    
    [actionSheet addButtonWithTitle:@"bitrate800"];
    if (700*1000 >= minBitrate) {
        [actionSheet addButtonWithTitle:@"bitrate700"];
    }
    if (600*1000 >= minBitrate) {
        [actionSheet addButtonWithTitle:@"bitrate600"];
    }
    if (500*1000 >= minBitrate) {
        [actionSheet addButtonWithTitle:@"bitrate500"];
    }
    if (400*1000 >= minBitrate) {
        [actionSheet addButtonWithTitle:@"bitrate400"];
    }
    if (300*1000 >= minBitrate) {
        [actionSheet addButtonWithTitle:@"bitrate300"];
    }
    if (200*1000 >= minBitrate) {
        [actionSheet addButtonWithTitle:@"bitrate200"];
    }
    if (100*1000 >= minBitrate) {
        [actionSheet addButtonWithTitle:@"bitrate100"];
    }
    
    [actionSheet showInView:self.view];
}

- (IBAction)videoPreset:(id)sender
{
    self.showingSettingsOfType = kSettingTypePreset;
    
    NSString *title = @"Video session preset";
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                              delegate:self
                                                     cancelButtonTitle:nil
                                                destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Low (suitable for sharing over 3G)",
                                  @"Medium (suitable for sharing over WiFi)",
                                  @"High (high quality video and audio)",
                                  @"352x288 (CIF quality)",
                                  @"640x480 (VGA quality)",
                                  @"1280x720 (720p quality)",
                                  @"1920x1080 (1080p full HD quality)",
                                  @"Automatic",
                                  nil];

    [actionSheet showInView:self.view];
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (self.showingSettingsOfType) {
        case kSettingTypeMinBitrate:
            
            switch (buttonIndex) {
                case 0:
                    [VideoUtils setMinBitrate:(100 * 1000)];
                    break;
                case 1:
                    [VideoUtils setMinBitrate:(200 * 1000)];
                    break;
                case 2:
                    [VideoUtils setMinBitrate:(300 * 1000)];
                    break;
                case 3:
                    [VideoUtils setMinBitrate:(400 * 1000)];
                    break;
                case 4:
                    [VideoUtils setMinBitrate:(500 * 1000)];
                    break;
                case 5:
                    [VideoUtils setMinBitrate:(600 * 1000)];
                    break;
                case 6:
                    [VideoUtils setMinBitrate:(700 * 1000)];
                    break;
                case 7:
                    [VideoUtils setMinBitrate:(800 * 1000)];
                    break;
                default:
                    break;
            }
            
            [self updateMinBitrateButton];
            
            break;
        case kSettingTypeMaxBitrate:
            
            switch (buttonIndex) {
                case 0:
                    [VideoUtils setMaxBitrate:(800 * 1000)];
                    break;
                case 1:
                    [VideoUtils setMaxBitrate:(700 * 1000)];
                    break;
                case 2:
                    [VideoUtils setMaxBitrate:(600 * 1000)];
                    break;
                case 3:
                    [VideoUtils setMaxBitrate:(500 * 1000)];
                    break;
                case 4:
                    [VideoUtils setMaxBitrate:(400 * 1000)];
                    break;
                case 5:
                    [VideoUtils setMaxBitrate:(300 * 1000)];
                    break;
                case 6:
                    [VideoUtils setMaxBitrate:(200 * 1000)];
                    break;
                case 7:
                    [VideoUtils setMaxBitrate:(100 * 1000)];
                    break;
                default:
                    break;
            }
            
            [self updateMaxBitrateButton];
            
            break;
        case kSettingTypePreset:
            
            switch (buttonIndex) {
                case 0:
                    [VideoUtils setVideoSessionPreset:AVCaptureSessionPresetLow];
                    break;
                case 1:
                    [VideoUtils setVideoSessionPreset:AVCaptureSessionPresetMedium];
                    break;
                case 2:
                    [VideoUtils setVideoSessionPreset:AVCaptureSessionPresetHigh];
                    break;
                case 3:
                    [VideoUtils setVideoSessionPreset:AVCaptureSessionPreset352x288];
                    break;
                case 4:
                    [VideoUtils setVideoSessionPreset:AVCaptureSessionPreset640x480];
                    break;
                case 5:
                    [VideoUtils setVideoSessionPreset:AVCaptureSessionPreset1280x720];
                    break;
                case 6:
                    [VideoUtils setVideoSessionPreset:AVCaptureSessionPreset1920x1080];
                    break;
                case 7:
                    [VideoUtils setVideoSessionPreset:VIDEO_PRESET_AUTO];
                    break;
                default:
                    break;
            }
            
            [self.broadcastService setVideoSessionPreset:[VideoUtils videoSessionPreset] failure:^(NSError *error) {
                NSLog(@"setVideoSessionPresetFailure");
            }];
            
            [self updateVideoPresetButton];
            
            break;
        default:
            break;
    }
}

- (void) showTestEvents
{
    [self showStream];
    
    User *author1 = [[User alloc] init];
    author1.uuid = @"1";
    author1.firstName = @"Author1";
    author1.lastName = @"Author1";
    author1.facebookID = @"1025788014115458";
    
    User *author2 = [[User alloc] init];
    author2.uuid = @"2";
    author2.firstName = @"Author2";
    author2.lastName = @"Author2";
    author2.facebookID = @"1435388136774643";
    
    User *author3 = [[User alloc] init];
    author3.uuid = @"3";
    author3.firstName = @"Author3";
    author3.lastName = @"Author3";
    author3.facebookID = @"1559422084321695";
    
    User *author4 = [[User alloc] init];
    author4.uuid = @"4";
    author4.firstName = @"Author3";
    author4.lastName = @"Author3";
    author4.facebookID = @"1400334393623730";
     
    self.watchers = [NSMutableArray arrayWithObjects:author1, author2, nil];
    [self.watchersContainer reloadData];
     
    Comment *comment1 = [[Comment alloc] init];
    comment1.uuid = @"1";
    comment1.type = kStreamEventTypeJoin;
    comment1.author = author1;
    
    Comment *comment2 = [[Comment alloc] init];
    comment2.uuid = @"2";
    comment2.type = kStreamEventTypeLeave;
    comment2.author = author1;
    
    Comment *comment3 = [[Comment alloc] init];
    comment3.uuid = @"3";
    comment3.type = kStreamEventTypeComment;
    comment3.text = @"Loren ipsum";
    comment3.author = author2;
    
    Comment *comment4 = [[Comment alloc] init];
    comment4.uuid = @"4";
    comment4.type = kStreamEventTypeComment;
    comment4.text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit.";
    comment4.author = author3;
    
    Comment *comment5 = [[Comment alloc] init];
    comment5.uuid = @"5";
    comment5.type = kStreamEventTypeComment;
    comment5.text = @"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis.";
    comment5.author = author4;
    
    NSArray *events = [NSArray arrayWithObjects:comment1, comment2, comment3, comment4, comment5, nil];
    [self handleMetadataEvents:events];
    
}

- (void) updateTestEvents
{
    User *author1 = [[User alloc] init];
    author1.uuid = @"1";
    author1.firstName = @"Author1";
    author1.lastName = @"Author1";
    author1.facebookID = @"1025788014115458";
    
    User *author2 = [[User alloc] init];
    author2.uuid = @"2";
    author2.firstName = @"Author2";
    author2.lastName = @"Author2";
    author2.facebookID = @"1435388136774643";
    
    User *author3 = [[User alloc] init];
    author3.uuid = @"3";
    author3.firstName = @"Author3";
    author3.lastName = @"Author3";
    author3.facebookID = @"1559422084321695";
    
    User *author4 = [[User alloc] init];
    author4.uuid = @"4";
    author4.firstName = @"Author3";
    author4.lastName = @"Author3";
    author4.facebookID = @"1400334393623730";
    
    Comment *comment1 = [[Comment alloc] init];
    comment1.uuid = @"1";
    comment1.type = kStreamEventTypeJoin;
    comment1.author = author1;
    
    Comment *comment2 = [[Comment alloc] init];
    comment2.uuid = @"2";
    comment2.type = kStreamEventTypeLeave;
    comment2.author = author1;
    
    Comment *comment3 = [[Comment alloc] init];
    comment3.uuid = @"3";
    comment3.type = kStreamEventTypeLeave;
    comment3.text = @"Loren ipsum";
    comment3.author = author2;
    
    Comment *comment4 = [[Comment alloc] init];
    comment4.uuid = @"4";
    comment4.type = kStreamEventTypeJoin;
    comment4.text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit.";
    comment4.author = author3;
    
    Comment *comment5 = [[Comment alloc] init];
    comment5.uuid = @"5";
    comment5.type = kStreamEventTypeJoin;
    comment5.text = @"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis.";
    comment5.author = author4;
    
    NSArray *events = [NSArray arrayWithObjects:comment1, comment2, comment3, comment4, comment5, nil];
    [self handleMetadataEvents:events];
}

@end
