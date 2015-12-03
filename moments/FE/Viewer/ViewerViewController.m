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
//  ViewerViewController.m
//  moments
//
//  Created by MobileMan GmbH on 13/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "ViewerViewController.h"
#import "AVPlayerView.h"
#import "ServiceFactory.h"
#import "Location.h"
#import "UserService.h"
#import "UIImageView+Haneke.h"
#import "fe_defines.h"
#import "WatcherCollectionViewCell.h"
#import "Comment.h"
#import "StreamMetadata.h"

#import "SVProgressHUD.h"

#define MAX_WATCHERS_COUNT 4
#define MAX_COMMENTS_COUNT 4
#define ANIMATION_DURATION 0.25

#define COMMENT_ANIMATION_DURATION 1.0
#define COMMENT_TERMINATION_ANIMATION_DURATION 0.5
#define WATCHER_ANIMATION_DURATION 1.0
#define WATCHER_TERMINATION_ANIMATION_DURATION 0.5

#define kPlayerDurationChangedNotification @"DurationChanged"
#define kPlayerSeekableRangeChangedNotification @"SeekableRangeChanged"

#define CLOSED_LABEL @"CLOSED"

#define kPlayerItemStatus @"status"

@implementation ViewerViewController

static NSString * PlayerStatusContext = @"PlayerStatus";
static NSString * PlayerRateContext = @"PlayerRate";
static NSString * CurrentItemContext = @"CurrentItem";
static NSString * PlaybackLikelyToKeepUp = @"PlaybackLikelyToKeepUp";
static NSString * ItemStatusContext = @"ItemStatus";

- (id) init {
    self = [super init];
    if(self){
        
    }
    return self;
}

- (void)cleanup {
    self.streamService.delegate = nil;
    self.playbackView.player = nil;
    self.playbackView = nil;
    [self.playerItem removeObserver:self forKeyPath:kPlayerItemStatus];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:self.playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Viewer";
    [self.navigationItem setHidesBackButton:NO];
    
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
    
    //commentTextField
    if (!self.isArchivedStream) {
        self.commentTextField.font = MOMENTS_FONT_TITLE_1;
        UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
        self.commentTextField.leftViewMode = UITextFieldViewModeAlways;
        self.commentTextField.leftView = leftView;
        self.commentTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Say something..." attributes:@{NSForegroundColorAttributeName: MOMENTS_COLOR_WHITE}];
    } else {
        [self.commentTextField removeFromSuperview];
        self.commentTextField = nil;
    }
    
    //live label
    self.liveLabel.font = MOMENTS_FONT_SUBHEAD_1;
    [self setLiveLabelText:@"Buffering..."];
    
    //stream status
    [self updateStatus:0];
    
    //watchers & comments
    self.watchers = [[NSMutableArray alloc] init];
    
    self.comments = [[NSMutableDictionary alloc] init];
    self.commentsViews = [[NSMutableArray alloc] init];
    
    //watchersContainer
    self.watchersContainer.clipsToBounds = YES;
    
    //commentsContainer
    self.commentsContainer.clipsToBounds = YES;
    
    //stream header
    if (self.user != nil) {
        [self updateStreamHeader];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerSystemNotification:) name:kPlayerDurationChangedNotification object:nil];
    
    //start
    self.streamService = [ServiceFactory streamService:self];
    [self startStream];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self cleanup];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.player pause];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [self cleanup];
}

- (IBAction)back:(id)sender {
    
    [self.player pause];
    
    if (!self.isArchivedStream) {
        [self.streamService leaveBroadcast:self.user.stream success:^(StreamMetadata *metadata) {
            NSLog(@"leaveBroadcast success");
        } failure:^(NSError *error) {
            NSLog(@"leaveBroadcast failure");
        }];
    }
    
    [self.delegate didCloseViewer];
    [self.navigationController popViewControllerAnimated:YES];
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

- (void)reconnectToStream {
    if (self.streamMetadata && self.streamMetadata.state == kStreamStateClosed) {
        [self back:self];
        return;
    }
    
    NSLog(@"Reconnect to stream finished");
    self.reconnectLabel.hidden = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self playStreamInternal];
    });
}

- (void)reconnectToStreamIfNeeded {
    if (self.tryReconnect) {
        self.tryReconnect = false;
        
        [self reconnectToStream];
    }
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
    
    if (self.user) {
        if (self.user.stream) {
            if (self.user.stream.location) {
                
                locationItem = self.user.stream.location.city;
                
                if (locationItem.length > 0) {
                    locationString = locationItem;
                }
                
                locationItem = self.user.stream.location.country;
                
                if (locationItem.length > 0) {
                    if (locationString.length > 0) {
                        locationString = [NSString stringWithFormat:@"%@, %@", locationString, locationItem];
                    } else {
                        locationString = [NSString stringWithFormat:@"%@", locationItem];
                    }
                    
                }
                /*
                locationItem = self.user.stream.location.state;
                
                if (locationItem.length > 0) {
                    locationString = [NSString stringWithFormat:@"%@, %@", locationString, locationItem];
                }*/
            }
        }
    }
    
    if (locationString.length == 0) {
        locationString = @"Somewhere";
    }
    
    return locationString;
}

- (NSString*) getStreamTitleString {
    NSString *result = @"";
    
    result = self.user.stream.text;
    if (result.length == 0) {
        result = @"";
    }
    
    return result;
}

- (void) updateStreamHeader
{
    self.streamUserNameLabel.text = [NSString stringWithFormat:@"%@ %@", self.user.firstName, self.user.lastName];
    self.streamLocationLabel.text = [self getStreamLocationString];
    self.streamLocationIcon.hidden = NO;
    
    //user image
    NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",@"https://graph.facebook.com/",self.user.facebookID,@"/picture?type=large"]];
    [self.streamUserImageView hnk_setImageFromURL:imageUrl];
    
    //location
    [self updateStreamLocation];
}

- (void) startStream
{
    if (self.stream) {
        [[ServiceFactory userService] profile:self.stream.user.uuid success:^(User *user) {
            self.user = user;
            [self playStream:self.stream];
            
            if (self.user != nil) {
                [self updateStreamHeader];
            }
            
        } failure:^(NSError *error) {
            NSLog(@"user profile failure");
        }];
    } else {
        
        if (self.user != nil) {
            
            [self playStream:self.user.stream];
            
        } else if(self.userUID != nil) {
            
            [[ServiceFactory userService] profile:self.userUID success:^(User *user) {
                self.user = user;
                [self playStream:self.user.stream];
                
                if (self.user != nil) {
                    [self updateStreamHeader];
                }
                
            } failure:^(NSError *error) {
                NSLog(@"user profile failure");
            }];
        }
    }
}

- (AVPlayerItem *)createAVPlayerItem:(NSURL *)url {
    if (self.playerItem) {
        [self.playerItem removeObserver:self forKeyPath:kPlayerItemStatus context:&ItemStatusContext];
    }
    
    AVPlayerItem * playerItem = [AVPlayerItem playerItemWithURL:url];
    [playerItem addObserver:self forKeyPath:kPlayerItemStatus options:0 context:&ItemStatusContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemNotification:) name:nil object:playerItem];

    return playerItem;
}

- (void)playStreamInternal {
    if (self.streamUrl != nil) {
        self.playerItem = [self createAVPlayerItem:self.streamUrl];
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        [self.player setActionAtItemEnd:AVPlayerActionAtItemEndPause];
        [self.playbackView setPlayer:self.player];
    }
}

- (void) playStream:(Stream*)stream
{
    if (stream != nil) {
        
        NSURL *thumbnailURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/poster_%@", stream.thumbnailBaseUrl, stream.thumbnailFileName]];
        NSURLRequest* request = [NSURLRequest requestWithURL:thumbnailURL];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
                                if (!error) {
                                    UIImage *thumbnail = [UIImage imageWithData:data];
                                    self.thumbnailView.image = thumbnail;
                                }
        }];
        
        if (self.isArchivedStream) {
            self.streamUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/vod.m3u8", stream.videoBaseUrl]];
            [self playStreamInternal];
        } else {
            self.streamUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", stream.videoBaseUrl, stream.videoFileName]];
            if (stream.state == kStreamStateStreaming) {
                [self playStreamInternal];
            }
        }
        
        if (!self.isArchivedStream) {
            [self.streamService joinBroadcast:stream success:^(StreamMetadata *metadata) {
                
                if (metadata.state == kStreamStateStreaming) {
                    [self playStreamInternal];
                }
                
                if ([metadata isStreamClosed]) {
                    [self showStreamClosedAlert];
                }
                
                NSLog(@"joinBroadcast success");
            } failure:^(NSError *error) {
                NSLog(@"joinBroadcast failure");
            }];
        }
        
        
    } else {
         NSLog(@"stream is nil");
    }
    
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if(object == self.playerItem && [keyPath isEqualToString:@"status"]){
        NSLog(@"playerItem.status = %ld", (long)self.playerItem.status);
        if( self.playerItem.status == 1){
            if (self.player.rate < 1.0 ) {
                if (self.isArchivedStream) {
                    [self setLiveLabelText:@"Replay"];
                } else if ([self.streamMetadata isStreamClosed]) {
                    [self setLiveLabelText:CLOSED_LABEL];
                } else {
                    [self setLiveLabelText:@"LIVE"];
                }
                [self.spinner stopAnimating];
                [self.player play];
            }
        }
        if(self.playerItem.status == AVPlayerItemStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
            if ([self.streamMetadata isStreamClosed] || self.isArchivedStream) {
                [self back:self];
            } else {
                [self reconnectToStream];
            }
        }
        
        if(context == AVPlayerItemDidPlayToEndTimeNotification){
            NSLog(@"AVPlayerItemDidPlayToEndTimeNotification");
        }else if(context == AVPlayerItemFailedToPlayToEndTimeNotification){
            NSLog(@"AVPlayerItemFailedToPlayToEndTimeNotification");
        }else if(context == AVPlayerItemNewAccessLogEntryNotification){
            NSLog(@"AVPlayerItemNewAccessLogEntryNotification");
        }else if(context == AVPlayerItemNewErrorLogEntryNotification){
            NSLog(@"AVPlayerItemNewErrorLogEntryNotification");
        }else if(context == AVPlayerItemPlaybackStalledNotification){
            self.reconnectLabel.hidden = NO;
            NSLog(@"AVPlayerItemPlaybackStalledNotification");
            if (self.isArchivedStream || [self.streamMetadata isStreamClosed]) {
                [self back:self];
            }
            
        }else if(context == AVPlayerItemTimeJumpedNotification){
            self.reconnectLabel.hidden = YES;
            NSLog(@"AVPlayerItemTimeJumpedNotification");
        }
    } else if(object == self.player && [keyPath isEqualToString:@"status"]) {
        NSLog(@"player status: %ld", (long)self.player.status);
    }
}

-(void)playerItemNotification:(NSNotification *)notification
{
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), notification.name);
    if (notification.name == AVPlayerItemDidPlayToEndTimeNotification) {
        if ([self.streamMetadata isStreamClosed] || self.isArchivedStream) {
            [self back:self];
            return;
        }
        
        self.tryReconnect = true;
        
        self.reconnectLabel.hidden = NO;
        
    } else if (notification.name == AVPlayerItemPlaybackStalledNotification) {
        
        if (self.isArchivedStream) {
            [self back:self];
        } else {
            self.reconnectLabel.hidden = NO;
        }
        
    }else if (notification.name == AVPlayerItemNewAccessLogEntryNotification) {

        self.thumbnailView.image = nil;
        
    } else if (notification.name == AVPlayerItemTimeJumpedNotification) {
        
        self.reconnectLabel.hidden = YES;
        
    } else if (notification.name == AVPlayerItemFailedToPlayToEndTimeNotification) {
        AVPlayerItemErrorLogEvent *event = [self.playerItem.errorLog.events lastObject];
        LogError(@"%@: Error log: (%d) %@", NSStringFromSelector(_cmd), event.errorStatusCode, event.errorComment);
        if ([self.streamMetadata isStreamClosed] || self.isArchivedStream) {
            [self back:self];
        } else {
            // -12660 HTTP 403: Forbidden
            if (event.errorStatusCode == -12660) {
                [self reconnectToStream];
            }
        }
        
    } else if (notification.name == AVPlayerItemNewErrorLogEntryNotification) {
        AVPlayerItemErrorLogEvent *event = [self.playerItem.errorLog.events lastObject];
        NSLog(@"%@: Error log: (%d) %@", NSStringFromSelector(_cmd), event.errorStatusCode, event.errorComment);
        // -12642 Playlist File unchanged for 2 consecutive reads
        // -12645 restarting too far ahead (-20.16s)
        if (event.errorStatusCode != -12642 && event.errorStatusCode != -12645) {
            if ([self.streamMetadata isStreamClosed]) {
                [self back:self];
            }
        } else  if (self.isArchivedStream) {
            //[self back:self];
        }
    }
    //[self.player seekToTime:kCMTimeZero];
}

-(void)playerSystemNotification:(NSNotification *)notification
{
    if ([notification.name isEqualToString:kPlayerDurationChangedNotification] || [notification.name isEqualToString:kPlayerSeekableRangeChangedNotification]) {
        NSLog(@"%@: %@", NSStringFromSelector(_cmd), notification.name);
        if (self.player && self.playerItem) {
            [self reconnectToStreamIfNeeded];
        }
    }
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

- (void)showStreamClosedAlert {
    [self setLiveLabelText:CLOSED_LABEL];
    [SVProgressHUD setBackgroundColor:MOMENTS_COLOR_RED];
    [SVProgressHUD setForegroundColor:MOMENTS_COLOR_WHITE];
    [SVProgressHUD setFont:MOMENTS_FONT_TITLE_1];
    [SVProgressHUD setCornerRadius:0.0];
    [SVProgressHUD showStatus:[NSString stringWithFormat:@"Broadcast has been closed."]];
    
}

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

- (void)streamService:(id<StreamService>)service didReceiveStreamMetadadata:(StreamMetadata*)metadata {
    StreamMetadata * previousMetadata = self.streamMetadata;
    self.streamMetadata = metadata;
    [self updateStatus:metadata.watchersCount];
    
    switch (metadata.state) {
        case kStreamStateStreaming: {
            
            if (self.player) {
                if (self.player.error) {
                    [self playStreamInternal];
                }
            } else {
                [self playStreamInternal];
            }
        }
            break;
        case kStreamStateClosed: {
             // show CLOSED alert only once
            if (previousMetadata == nil || previousMetadata.state != kStreamStateClosed) {
                [self showStreamClosedAlert];
            }
            
            return;
        }
            break;
        default:
            break;
    }
    
    AVPlayerItemAccessLogEvent *event = [self.playerItem.accessLog.events lastObject];
    //NSLog(@"indicated bitrate is %f", [event indicatedBitrate]);
    //NSLog(@"observerd bitrate is %.0f kbps", [event observedBitrate]/1024);
    if (event) {
        //self.videoBitrate.text = [NSString stringWithFormat:@"%.0f kbps", [event observedBitrate]/1024];
        //self.videoBitrate.hidden = NO;
    }
    
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
        [self.commentsViews removeObject:commentView];
    }];
}

#pragma mark Keyboard

- (void) animateTextFieldUp:(BOOL)up distance:(float)distance
{
    if (up) {
        [UIView beginAnimations: @"animUp" context: nil];
        [UIView setAnimationBeginsFromCurrentState: YES];
        [UIView setAnimationDuration: ANIMATION_DURATION];
        self.view.frame = CGRectMake(0, -distance, self.view.frame.size.width, self.view.frame.size.height);
        [UIView commitAnimations];
    } else {
        [UIView beginAnimations: @"animDown" context: nil];
        [UIView setAnimationBeginsFromCurrentState: YES];
        [UIView setAnimationDuration: ANIMATION_DURATION];
        self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [UIView commitAnimations];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    if (self.commentTextField.text.length > 0) {
        [self.streamService postComment:self.user.stream text:self.commentTextField.text success:^(StreamMetadata *metadata) {
            self.commentTextField.text = @"";
            NSLog(@"postComment success");
        } failure:^(NSError *error) {
            NSString *message = [NSString stringWithFormat:@"Post comment failure."];
            [SVProgressHUD setBackgroundColor:MOMENTS_COLOR_RED];
            [SVProgressHUD setForegroundColor:MOMENTS_COLOR_WHITE];
            [SVProgressHUD setFont:MOMENTS_FONT_TITLE_1];
            [SVProgressHUD setCornerRadius:0.0];
            [SVProgressHUD showStatus:message];
            NSLog(@"postComment failure");
        }];
    }

    return YES;
}

- (void)keyboardWillBeShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    [self animateTextFieldUp:YES distance:kbSize.height];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [self animateTextFieldUp:NO distance:0.0];
}

@end
