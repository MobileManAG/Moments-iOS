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
//  FriendsViewController.h
//  moments
//
//  Created by MobileMan GmbH on 22/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBSDKShareKit/FBSDKAppInviteContent.h>
#import <FBSDKShareKit/FBSDKAppInviteDialog.h>
#import "FriendsTableViewCell.h"
#import "Friend.h"

@interface FriendsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, FBSDKAppInviteDialogDelegate, UIPopoverPresentationControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet UIButton *backButton;
@property (nonatomic, strong) IBOutlet UIButton *forwardButton;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIButton *inviteFriendsButton;
@property (nonatomic, strong) IBOutlet NSArray *friends;
@property (nonatomic, strong) Friend *selectedFriend;
@property (assign) BOOL isCommingFromSignIn;

- (IBAction)back:(id)sender;
- (IBAction)forward:(id)sender;
- (IBAction)inviteFriends:(id)sender;

@end