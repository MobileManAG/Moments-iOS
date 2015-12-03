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
//  SettingsViewController.m
//  moments
//
//  Created by MobileMan GmbH on 13/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingsTableViewCell.h"
#import "FriendsViewController.h"
#import "MyMomentsViewController.h"
#import "ShareViewController.h"
#import "StreamSettingsViewController.h"
#import "ServiceFactory.h"
#import "fe_defines.h"

@implementation SettingsViewController

- (id) init {
    self = [super init];
    if(self){
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Settings";
    
    self.settingsButton.backgroundColor = [UIColor clearColor];
    UIImage *settingsButtonImage = [UIImage imageNamed:@"Logo_48.png"];
    [self.settingsButton setBackgroundImage:settingsButtonImage forState:UIControlStateNormal];
    [self.settingsButton setBackgroundImage:settingsButtonImage forState:UIControlStateHighlighted];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.settingsButton.hidden = NO;
}

- (IBAction)back:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate didCloseSettings];
    }];
}

- (void)logout
{
    [[ServiceFactory userService] signout:^{
        [self dismissViewControllerAnimated:YES completion:^{
            [self.delegate didLogout];
        }];
    } failure:^(NSError *error) {
        NSLog(@"LOGOUT ERROR");
        [self dismissViewControllerAnimated:YES completion:^{
            [self.delegate didLogout];
        }];
    }];
}

- (void)share
{
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentTitle = @"Moments";
    content.contentDescription = @"Stream moments with friends and families around the world!";
    content.contentURL = [NSURL URLWithString:MOMENTS_APP_LINK];
    content.imageURL = [NSURL URLWithString:MOMENTS_INVITE_IMAGE_LINK];
    [FBSDKShareDialog showFromViewController:self
                                 withContent:content
                                    delegate:self];

}

- (StreamSettingsViewController *) getStreamSettingsViewController
{
    StreamSettingsViewController *result = nil;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    result = [storyboard instantiateViewControllerWithIdentifier:@"streamSettingsViewController"];
    
    return result;
}

- (FriendsViewController *) getFriendsViewController
{
    FriendsViewController *result = nil;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    result = [storyboard instantiateViewControllerWithIdentifier:@"friendsViewController"];
    
    return result;
}

- (MyMomentsViewController *) getMyMomentsViewController
{
    MyMomentsViewController *result = nil;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    result = [storyboard instantiateViewControllerWithIdentifier:@"myMomentsViewController"];
    
    return result;
}

- (ShareViewController *) getShareViewController
{
    ShareViewController *result = nil;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    result = [storyboard instantiateViewControllerWithIdentifier:@"shareViewController"];
    
    return result;
}

#pragma mark FBSDKSharingDelegate

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

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    //int section = indexPath.section;
    
    static NSString *cellIdentifier = @"SettingsTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    SettingsTableViewCell *settingsTableViewCell = (SettingsTableViewCell *)cell;
    if (settingsTableViewCell == nil) {
        settingsTableViewCell = [[SettingsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        
        
    }
    
    switch (row) {
        case 0:
            settingsTableViewCell.nameLabel.text = @"My friends";
            break;
        case 1:
            settingsTableViewCell.nameLabel.text = @"My Moments";
            break;
        case 2:
            settingsTableViewCell.nameLabel.text = @"Share";
            break;
        case 3:
            settingsTableViewCell.nameLabel.text = @"Logout";
            break;
        case 4:
            settingsTableViewCell.nameLabel.text = @"Video settings";
            break;
    }
    
    if (row == 0) {
        settingsTableViewCell.isFirstCell = YES;
    }
    
    cell = settingsTableViewCell;
    //cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [cell setNeedsDisplay];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSInteger row = indexPath.row;
    //int section = indexPath.section;
    
    UIViewController *controllerToPush = nil;
    
    switch (row) {
        case 0:
            controllerToPush = [self getFriendsViewController];
            break;
        case 1:
            controllerToPush = [self getMyMomentsViewController];
            break;
        case 2:
            //controllerToPush = [self getShareViewController];
            [self share];
            break;
        case 3:
            [self logout];
            break;
        case 4:
            controllerToPush = [self getStreamSettingsViewController];
            break;
        default:
            break;
    }
    
    if (controllerToPush != nil) {
        [self.navigationController pushViewController:controllerToPush animated:YES];
    }
}

@end
