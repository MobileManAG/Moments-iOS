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
//  HomeViewController.h
//  moments
//
//  Created by MobileMan GmbH on 13/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VerticalButton.h"
#import "StreamService.h"
#import "CallViewController.h"
#import "SettingsViewController.h"
#import "BroadcasterViewController.h"
#import "SignInViewController.h"
#import "ViewerViewController.h"
#import "HomeTableViewCell.h"

@interface HomeViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, SignInViewControllerDelegate, SettingsViewControllerDelegate, CallViewControllerDelegate, BroadcasterViewControllerDelegate, ViewerViewControllerDelegate, StreamServiceDelegate, HomeTableViewCellDelegate>

@property (nonatomic, strong) id<StreamService> streamService;

@property (nonatomic, strong) IBOutlet UIButton *settingsButton;
@property (nonatomic, strong) IBOutlet VerticalButton *fbButton;
@property (nonatomic, strong) IBOutlet UIButton *startBroadcastButton;
@property (nonatomic, strong) IBOutlet UITextField *titleTextField;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) IBOutlet NSArray *users;

@property (nonatomic, strong) id<UIViewControllerTransitioningDelegate> transitioningSettingsDelegate;

@property (assign) BOOL isShowingCall;
@property (assign) BOOL isShowingSettings;
@property (assign) BOOL isShowingLogin;
@property (assign) BOOL isBroadcasting;
@property (assign) BOOL isViewingStream;

@property (assign) BOOL isFBSharingActive;

- (IBAction)settings:(id)sender;
- (IBAction)startBroadcast:(id)sender;
- (IBAction)fbPostSet:(id)sender;

@end
