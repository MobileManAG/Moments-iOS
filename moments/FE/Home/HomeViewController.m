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
//  HomeViewController.m
//  moments
//
//  Created by MobileMan GmbH on 13/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "HomeViewController.h"
#import "fe_defines.h"
#import "mom_notifications.h"
#import "ServiceFactory.h"
#import "Settings.h"
#import "Slice.h"
#import "MomentsNavigationController.h"
#import "SettingsTransitioningDelegate.h"
#import "User.h"
#import "UIImageView+Haneke.h"
#import <FBSDKCoreKit/FBSDKAccessToken.h>
#import "SVProgressHUD.h"

#define ANIMATION_DURATION 0.25

@implementation HomeViewController

- (id) init {
    self = [super init];
    if(self){
        
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.streamService = [ServiceFactory streamService:self];
    self.title = @"Home";
    [self.navigationItem setHidesBackButton:YES];
    
    UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.tableView addSubview:refreshView];
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(updateLiveStreams) forControlEvents:UIControlEventValueChanged];
    [refreshView addSubview:self.refreshControl];
    
    //settings
    self.transitioningSettingsDelegate = [[SettingsTransitioningDelegate alloc] init];
    
    self.settingsButton.backgroundColor = [UIColor clearColor];
    UIImage *settingsButtonImage = [UIImage imageNamed:@"Logo_48.png"];
    [self.settingsButton setBackgroundImage:settingsButtonImage forState:UIControlStateNormal];
    [self.settingsButton setBackgroundImage:settingsButtonImage forState:UIControlStateHighlighted];
    
    //title
    self.titleTextField.font = MOMENTS_FONT_TITLE_1;
    self.titleTextField.backgroundColor = MOMENTS_COLOR_WHITE_TRANSPARENT;
    
    //start
    NSMutableParagraphStyle *styleSignInButton = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [styleSignInButton setAlignment:NSTextAlignmentCenter];
    [styleSignInButton setLineBreakMode:NSLineBreakByWordWrapping];
    
    NSDictionary *dict = @{NSUnderlineStyleAttributeName:@(NSUnderlineStyleNone),
                           NSFontAttributeName:MOMENTS_FONT_TITLE_1,
                           NSParagraphStyleAttributeName:styleSignInButton};
    
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] init];
    [attString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Start broadcast" attributes:dict]];
    [self.startBroadcastButton setAttributedTitle:attString forState:UIControlStateNormal];
    [[self.startBroadcastButton titleLabel] setTextColor:MOMENTS_COLOR_WHITE];
    [[self.startBroadcastButton titleLabel] setNumberOfLines:0];
    [[self.startBroadcastButton titleLabel] setLineBreakMode:NSLineBreakByWordWrapping];
    [self.startBroadcastButton setBackgroundColor:MOMENTS_COLOR_RED_SEMITRANSPARENT];
    
    //fb
    /*
    NSString *fbPostString = @"Post: On";
    if (![Settings broadcastFBSharingActive]) {
        fbPostString = @"Post: Off";
        self.fbButton.titleLabel.alpha = 0.5;
        [self.fbButton setSemitransparent:YES];
    } else {
        self.fbButton.titleLabel.alpha = 1.0;
        [self.fbButton setSemitransparent:NO];
    }*/
    NSString *fbPostString = @"Post: Off";
    self.fbButton.titleLabel.alpha = 0.5;
    [self.fbButton setSemitransparent:YES];
    [self.fbButton setTitle:fbPostString forState:UIControlStateNormal];
    [self.fbButton setTitle:fbPostString forState:UIControlStateHighlighted];
    [[self.fbButton titleLabel] setTextColor:MOMENTS_COLOR_WHITE];
    [[self.fbButton titleLabel] setFont:MOMENTS_FONT_BUTTON];
    [[self.fbButton titleLabel] setTextAlignment:NSTextAlignmentCenter];
    [self.fbButton setBackgroundColor:MOMENTS_COLOR_WHITE_TRANSPARENT];
    self.fbButton.verticalImageView.image = [UIImage imageNamed:@"FB_Logo.png"];
    
    NSDictionary *userInfoNotification = [Settings getAndClearAppLaunchBroadcastNotificationData];
    if (userInfoNotification.count > 0) {
        [self showCallView:userInfoNotification];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(friendBroadcastStarted:) name:MOMFriendBroadcastStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkUnreachable:) name:MOMNetworkUnreachableNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachable:) name:MOMNetworkReachableNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionExpired:) name:MOMSessionExpiredNotification object:nil];
    
}

- (void) viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MOMFriendBroadcastStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MOMNetworkUnreachableNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MOMNetworkReachableNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MOMSessionExpiredNotification object:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UserSession *userSession = [[ServiceFactory userService] currentSession];
    if( userSession != nil){
        [self updateLiveStreams];
    }
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) friendBroadcastStarted:(NSNotification *)notification
{
    if (self.isShowingLogin) {
        return;
    }
    
    UserSession *userSession = [[ServiceFactory userService] currentSession];
    if( userSession != nil){
        
        [self updateLiveStreams];
        
        NSString *action = [notification.userInfo objectForKey:@"action"];
        if (action != nil && [action isEqualToString:NOTIFICATION_ACTION_WATCH]) {
            NSString *userUID = [notification.userInfo objectForKey:@"userId"];
            if (self.isViewingStream) {
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
            [self didSelectWatch:userUID];
        } else {
            [self showCallView:notification.userInfo];
        }
    }
}

- (void) showCallView:(NSDictionary*)userInfo
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    CallViewController *callViewController = [storyboard instantiateViewControllerWithIdentifier:@"callViewController"];
    callViewController.delegate = self;
    callViewController.userInfoNotification = userInfo;
    UIViewController *presented = self.presentedViewController;
    
    if (self.isViewingStream) {
        return;
    }
    
    if (self.isBroadcasting) {
        return;
    }
    
    if (!self.isShowingCall) {
        if (presented!= nil) {
            self.isShowingCall = YES;
            [presented presentViewController:callViewController animated:YES completion:^{}];
        } else {
            self.isShowingCall = YES;
            [self presentViewController:callViewController animated:YES completion:^{}];
        }
    }
}

- (void)updateLiveStreams
{
    [self.streamService liveBroadcasts:^(id<Slice> streams) {
        
        NSMutableArray *usersArray = [[NSMutableArray alloc] init];
        
        for (int i=0; i < [streams.numberOfElements intValue]; i++) {
            User *user = [streams.content objectAtIndex:i];
            
            if (user.stream.state == kStreamStateStreaming) {
                [usersArray addObject:user];
            }
        }
        
        self.users = [usersArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *first = [(User*)obj1 lastName];
            NSString *second = [(User*)obj2 lastName];
            return [first compare: second];
        }];
        
        if ([self.refreshControl isRefreshing]) {
            [self.refreshControl endRefreshing];
        }
        
        [self.tableView reloadData];
        
        //NSLog(@"updateLiveStreams ok");
    } failure:^(NSError *error) {
        
        if ([self.refreshControl isRefreshing]) {
            [self.refreshControl endRefreshing];
        }
        
        NSLog(@"updateLiveStreams error");
    }];
}

# pragma mark HomeViewController

- (IBAction)settings:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    SettingsViewController *settingsViewController = [storyboard instantiateViewControllerWithIdentifier:@"settingsViewController"];
    settingsViewController.delegate = self;
    MomentsNavigationController *settingsNavigationController = [[MomentsNavigationController alloc] initWithRootViewController:settingsViewController];
    [settingsNavigationController setNavigationBarHidden:YES];
    [settingsNavigationController setTransitioningDelegate:self.transitioningSettingsDelegate];
    [self presentViewController:settingsNavigationController animated:YES completion:^{}];
    self.isShowingSettings = YES;
}
- (IBAction)startBroadcast:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    BroadcasterViewController *broadcasterViewController = [storyboard instantiateViewControllerWithIdentifier:@"broadcasterViewController"];
    broadcasterViewController.delegate = self;
    broadcasterViewController.isFBSharingActive = self.isFBSharingActive;
    
    NSString *broadcastTitle = nil;
    if (self.titleTextField.text.length > 0) {
        broadcastTitle = self.titleTextField.text;
    }
    
    self.titleTextField.text = @"";
    [self.titleTextField resignFirstResponder];
    
    broadcasterViewController.broadcastTitle = broadcastTitle;
    [self.navigationController pushViewController:broadcasterViewController animated:YES];
    self.isBroadcasting = YES;
}

- (IBAction)fbPostSet:(id)sender
{
    static NSString *fbPostStringOff = @"Post: Off";
    static NSString *fbPostStringOn = @"Post: On";
    
    if (self.isFBSharingActive) {
        self.isFBSharingActive = NO;
    //if ([Settings broadcastFBSharingActive]) {
        //[Settings setBroadcastFBSharingActive:NO];
        [self.fbButton setTitle:fbPostStringOff forState:UIControlStateNormal];
        [self.fbButton setTitle:fbPostStringOff forState:UIControlStateHighlighted];
        
        self.fbButton.titleLabel.alpha = 0.5;
        [self.fbButton setSemitransparent:YES];
        
    } else {
        if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
            
            //[Settings setBroadcastFBSharingActive:YES];
            self.isFBSharingActive = YES;
            [self.fbButton setTitle:fbPostStringOn forState:UIControlStateNormal];
            [self.fbButton setTitle:fbPostStringOn forState:UIControlStateHighlighted];
            
            self.fbButton.titleLabel.alpha = 1.0;
            [self.fbButton setSemitransparent:NO];
            
        } else {
            self.fbButton.enabled = NO;
            [[ServiceFactory userService] signin:YES success:^(User *session) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //[Settings setBroadcastFBSharingActive:YES];
                    self.isFBSharingActive = YES;
                    [self.fbButton setTitle:fbPostStringOn forState:UIControlStateNormal];
                    [self.fbButton setTitle:fbPostStringOn forState:UIControlStateHighlighted];
                    self.fbButton.enabled = YES;
                    
                    self.fbButton.titleLabel.alpha = 1.0;
                    [self.fbButton setSemitransparent:NO];
                });
                
            } failure:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //[Settings setBroadcastFBSharingActive:NO];
                    self.isFBSharingActive = NO;
                    [self.fbButton setTitle:fbPostStringOff forState:UIControlStateNormal];
                    [self.fbButton setTitle:fbPostStringOff forState:UIControlStateHighlighted];
                    self.fbButton.enabled = YES;
                    
                    self.fbButton.titleLabel.alpha = 0.5;
                    [self.fbButton setSemitransparent:YES];
                });
                
            }];
        }
    }
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.users count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    //int section = indexPath.section;
    
    static NSString *cellIdentifier = @"HomeTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    HomeTableViewCell *homeTableViewCell = (HomeTableViewCell *)cell;
    if (homeTableViewCell == nil) {
        homeTableViewCell = [[HomeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    User *user = [self.users objectAtIndex:row];
    if (user != nil) {
        homeTableViewCell.user = user;
        homeTableViewCell.delegate = self;
        homeTableViewCell.userNameLabel.text = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
        NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",@"https://graph.facebook.com/",user.facebookID,@"/picture?type=large"]];
        [homeTableViewCell.userImageView hnk_setImageFromURL:imageUrl];
    }
    
    if (row == 0) {
        homeTableViewCell.isFirstCell = YES;
    }
    
    cell = homeTableViewCell;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [cell setNeedsDisplay];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark StreamServiceDelegate

- (void)streamServiceLiveBroadcastsChanged:(id<StreamService>)service
{
    UserSession *userSession = [[ServiceFactory userService] currentSession];
    if( userSession != nil){
        [self updateLiveStreams];
    }
}

#pragma mark ViewerViewControllerDelegate

- (void) didCloseViewer
{
    self.isViewingStream = NO;
}

#pragma mark BroadcasterViewControllerDelegate

- (void) didCloseBroadcast
{
    self.isBroadcasting = NO;
}

#pragma mark SignInViewControllerDelegate

- (void) didLoginAndReceivedNotification:(NSNotification*)notification
{
    self.isShowingLogin = NO;
    
    if (notification != nil) {
        NSString *action = [notification.userInfo objectForKey:@"action"];
        if (action != nil && [action isEqualToString:NOTIFICATION_ACTION_WATCH]) {
            NSString *userUID = [notification.userInfo objectForKey:@"userId"];
            [self didSelectWatch:userUID];
        } else {
            //[self showCallView:notification.userInfo];
        }
    }
}

#pragma mark SettingsViewControllerDelegate

- (void) didCloseSettings
{
    self.isShowingSettings = NO;
}

- (void) didLogout
{
    self.isShowingSettings = NO;
    self.isShowingLogin = YES;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    SignInViewController *signInViewController = [storyboard instantiateViewControllerWithIdentifier:@"signInViewController"];
    signInViewController.delegate = self;
    [self.navigationController pushViewController:signInViewController animated:YES];
}

#pragma mark CallViewControllerViewDelegate

- (void) didSelectPass
{
    self.isShowingCall = NO;
}

- (void) didSelectWatch:(NSString*)userUID
{
    self.isShowingCall = NO;
    
    if (self.isShowingSettings) {
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    ViewerViewController *viewerViewController = [storyboard instantiateViewControllerWithIdentifier:@"viewerViewController"];
    viewerViewController.userUID = userUID;
    viewerViewController.delegate = self;
    self.isViewingStream = YES;
    [self.navigationController pushViewController:viewerViewController animated:YES];
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

#pragma mark Network reachability

- (void) networkUnreachable:(NSNotification*)aNotification
{
    NSString *message = [NSString stringWithFormat:@"Network unreachable"];
    [SVProgressHUD setBackgroundColor:MOMENTS_COLOR_RED];
    [SVProgressHUD setForegroundColor:MOMENTS_COLOR_WHITE];
    [SVProgressHUD setFont:MOMENTS_FONT_TITLE_1];
    [SVProgressHUD setCornerRadius:0.0];
    [SVProgressHUD showStatus:message];
}

- (void) networkReachable:(NSNotification*)aNotification
{
    /*
    NSString *message = [NSString stringWithFormat:@"Network reachable"];
    [SVProgressHUD setBackgroundColor:MOMENTS_COLOR_WHITE];
    [SVProgressHUD setForegroundColor:MOMENTS_COLOR_BLACK];
    [SVProgressHUD setFont:MOMENTS_FONT_TITLE_1];
    [SVProgressHUD setCornerRadius:0.0];
    [SVProgressHUD showStatus:message];
     */
}

#pragma mark Session expired

- (void) sessionExpired:(NSNotification*)aNotification
{
    NSString *message = [NSString stringWithFormat:@"Session expired. Please relogin"];
    [SVProgressHUD setBackgroundColor:MOMENTS_COLOR_RED];
    [SVProgressHUD setForegroundColor:MOMENTS_COLOR_WHITE];
    [SVProgressHUD setFont:MOMENTS_FONT_TITLE_1];
    [SVProgressHUD setCornerRadius:0.0];
    [SVProgressHUD showStatus:message];
}

#pragma mark HomeTableViewCellDelegate

- (void) didSelectWatchOf:(User*)user
{
    if (user != nil) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        ViewerViewController *viewerViewController = [storyboard instantiateViewControllerWithIdentifier:@"viewerViewController"];
        viewerViewController.user = user;
        viewerViewController.delegate = self;
        self.isViewingStream = YES;
        [self.navigationController pushViewController:viewerViewController animated:YES];
    }
}

@end
