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
//  FriendsViewController.m
//  moments
//
//  Created by MobileMan GmbH on 22/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "FriendsViewController.h"
#import "ServiceFactory.h"
#import "UserService.h"
#import "UserSession.h"
#import "UIImageView+Haneke.h"
#import "SVProgressHUD.h"
#import "fe_defines.h"
#import "NSError+Util.h"

@implementation FriendsViewController

- (id) init {
    self = [super init];
    if(self){
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.titleLabel.font = MOMENTS_FONT_DISPLAY_1;
    self.titleLabel.text = @"My friends";
    
    UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.tableView addSubview:refreshView];
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(updateFriendsList) forControlEvents:UIControlEventValueChanged];
    [refreshView addSubview:self.refreshControl];
    
    //invite
    NSMutableParagraphStyle *styleInviteButton = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [styleInviteButton setAlignment:NSTextAlignmentCenter];
    [styleInviteButton setLineBreakMode:NSLineBreakByWordWrapping];
    
    NSDictionary *dict = @{NSUnderlineStyleAttributeName:@(NSUnderlineStyleNone),
                           NSFontAttributeName:MOMENTS_FONT_TITLE_1,
                           NSParagraphStyleAttributeName:styleInviteButton};
    
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] init];
    [attString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Invite Facebook friends" attributes:dict]];
    [self.inviteFriendsButton setAttributedTitle:attString forState:UIControlStateNormal];
    [[self.inviteFriendsButton titleLabel] setTextColor:MOMENTS_COLOR_WHITE];
    [[self.inviteFriendsButton titleLabel] setNumberOfLines:0];
    [[self.inviteFriendsButton titleLabel] setLineBreakMode:NSLineBreakByWordWrapping];
    [self.inviteFriendsButton setBackgroundColor:MOMENTS_COLOR_GREEN];
    
    if (self.isCommingFromSignIn) {
        self.backButton.hidden = YES;
        self.forwardButton.hidden = NO;
    }
    
    UserSession *userSession = [[ServiceFactory userService] currentSession];
    if( userSession != nil){
        [self updateFriendsList];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)forward:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)inviteFriends:(id)sender
{
    FBSDKAppInviteContent *content =[[FBSDKAppInviteContent alloc] init]; //required app link, ios or android
    content.appLinkURL = [NSURL URLWithString:MOMENTS_APP_LINK];
    content.appInvitePreviewImageURL = [NSURL URLWithString:MOMENTS_INVITE_IMAGE_LINK];    
    [FBSDKAppInviteDialog showFromViewController:self withContent:content delegate:self];
}

- (void) updateFriendsList {
    
    [[ServiceFactory userService] friends:^(NSArray *appFriends, NSArray *invitableFriends) {
        
        NSMutableArray *users = [[NSMutableArray alloc] init];
        for (int i=0; i<appFriends.count; i++) {
            Friend *friend = [appFriends objectAtIndex:i];
            [users addObject:friend];
        }
        
        self.friends = [users sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *first = [(Friend*)obj1 lastName];
            NSString *second = [(Friend*)obj2 lastName];
            return [first compare: second];
        }];
        
        [self.tableView reloadData];
        
        [self.spinner stopAnimating];
        
        if ([self.refreshControl isRefreshing]) {
            [self.refreshControl endRefreshing];
        }
        
    } failure:^(NSError *error) {
        NSLog(@"friends failure");
        
        if ([error isMomentsErrorDomain]) {
            if (error.code == kErrorCodeFBMissingFriendsPermission) {
                
            }
        }
        
        [self.spinner stopAnimating];
        
        if ([self.refreshControl isRefreshing]) {
            [self.refreshControl endRefreshing];
        }
    }];
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.friends.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    //int section = indexPath.section;
    
    static NSString *cellIdentifier = @"ShareTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    FriendsTableViewCell *friendsTableViewCell = (FriendsTableViewCell *)cell;
    if (friendsTableViewCell == nil) {
        friendsTableViewCell = [[FriendsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    Friend *friend = [self.friends objectAtIndex:row];
    if (friend != nil) {
        friendsTableViewCell.userNameLabel.text = [NSString stringWithFormat:@"%@ %@", friend.firstName, friend.lastName];
        NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",@"https://graph.facebook.com/",friend.facebookID,@"/picture?type=large"]];
        [friendsTableViewCell.userImageView hnk_setImageFromURL:imageUrl];
        
        if (friend.blocked) {
            friendsTableViewCell.isBlockedFriend = YES;
        } else {
            friendsTableViewCell.isBlockedFriend = NO;
            
            if (friend.newFriend) {
                friendsTableViewCell.isNewFriend = YES;
            } else {
                friendsTableViewCell.isNewFriend = NO;
            }
        }
    }
    
    if (row == 0) {
        friendsTableViewCell.isFirstCell = YES;
    }
    
    cell = friendsTableViewCell;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [cell setNeedsDisplay];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    /*
    NSInteger row = indexPath.row;
    //int section = indexPath.section;
    
    Friend *friend = [self.friends objectAtIndex:row];
    if (friend != nil) {
        if (IS_IOS_8_OR_LATER) {
            [self askBlockUnblockFriend:friend onIndexPath:indexPath];
        } else {
            
            self.selectedFriend = friend;
            [self askBlockUnblockFriendIOS7OnIndexPath:indexPath];
        }
        
    }
     */
}

#pragma mark FBSDKAppInviteDialogDelegate

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results
{
    NSLog(@"app invite result: %@", results);
    
    BOOL complete = [[results valueForKeyPath:@"didComplete"] boolValue];
    NSString *completionGesture = [results valueForKeyPath:@"completionGesture"];
    
    // NOTE: the `cancel` result dictionary will be
    // {
    //   completionGesture = cancel;
    //   didComplete = 1;
    // }
    // else, it will only just `didComplete`
    
    if (completionGesture && [completionGesture isEqualToString:@"cancel"]) {
        NSString *message = @"Your invite has been canceled.";
        [SVProgressHUD setBackgroundColor:MOMENTS_COLOR_RED];
        [SVProgressHUD setForegroundColor:MOMENTS_COLOR_WHITE];
        [SVProgressHUD setFont:MOMENTS_FONT_TITLE_1];
        [SVProgressHUD setCornerRadius:0.0];
        [SVProgressHUD showStatus:message];
        return;
    }
    
    if (complete) { // if completionGesture is nil -> success
        NSString *message = @"Your invite has been sent.";
        [SVProgressHUD setBackgroundColor:MOMENTS_COLOR_WHITE];
        [SVProgressHUD setForegroundColor:MOMENTS_COLOR_BLACK];
        [SVProgressHUD setFont:MOMENTS_FONT_TITLE_1];
        [SVProgressHUD setCornerRadius:0.0];
        [SVProgressHUD showStatus:message];
        
        NSLog(@"Your invite has been sent.");
    }
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error
{
    NSLog(@"app invite error: %@", error.localizedDescription);
}

#pragma mark FriendsTableViewCellDelegate

- (void) blockFriend:(Friend*)friend
{
    [[ServiceFactory userService] blockFriend:friend success:^{
        
        NSString *message = [NSString stringWithFormat:@"%@ %@ has been blocked.", friend.firstName, friend.lastName];
        [SVProgressHUD setBackgroundColor:MOMENTS_COLOR_RED];
        [SVProgressHUD setForegroundColor:MOMENTS_COLOR_WHITE];
        [SVProgressHUD setFont:MOMENTS_FONT_TITLE_1];
        [SVProgressHUD setCornerRadius:0.0];
        [SVProgressHUD showStatus:message];
        friend.blocked = YES;
        self.selectedFriend = nil;
        [self.tableView reloadData];
        
    } failure:^(NSError *error) {
         NSLog(@"");
    }];
}

- (void) unblockFriend:(Friend*)friend
{
    [[ServiceFactory userService] unblockFriend:friend success:^{
        
        NSString *message = [NSString stringWithFormat:@"%@ %@ has been unblocked.", friend.firstName, friend.lastName];
        [SVProgressHUD setBackgroundColor:MOMENTS_COLOR_WHITE];
        [SVProgressHUD setForegroundColor:MOMENTS_COLOR_BLACK];
        [SVProgressHUD setFont:MOMENTS_FONT_TITLE_1];
        [SVProgressHUD setCornerRadius:0.0];
        [SVProgressHUD showStatus:message];
        friend.blocked = NO;
        self.selectedFriend = nil;
        [self.tableView reloadData];
        
    } failure:^(NSError *error) {
         NSLog(@"");
    }];
}

- (void) askBlockUnblockFriend:(Friend*)friend onIndexPath:(NSIndexPath*)indexPath
{
    
    NSString *title;
    //NSString *subtitle = @"Select you choice";
    NSString *actionTitle;
    
    if (friend.blocked) {
        title = [NSString stringWithFormat:@"Unblock %@ %@", friend.firstName, friend.lastName];
        //subtitle = @"";
        actionTitle = @"Unblock";
    } else {
        title = [NSString stringWithFormat:@"Block %@ %@", friend.firstName, friend.lastName];
        //subtitle = @"";
        actionTitle = @"Block";
    }
    
    UIAlertController* view = [UIAlertController alertControllerWithTitle:title
                                                                  message:nil//message:subtitle
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:actionTitle
                         style:UIAlertActionStyleDestructive
                         handler:^(UIAlertAction * action)
                         {
                             if (friend.blocked) {
                                 [self unblockFriend:friend];
                             } else {
                                 [self blockFriend:friend];
                             }
                             
                             [view dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 [view dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    [view addAction:ok];
    [view addAction:cancel];
    view.popoverPresentationController.sourceView = self.view;
    CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
    view.popoverPresentationController.sourceRect = cellRect;
    [self presentViewController:view animated:YES completion:nil];
}

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController
{
    NSLog(@"");
}

- (void) askBlockUnblockFriendIOS7OnIndexPath:(NSIndexPath*)indexPath
{
    NSString *title;
    //NSString *subtitle = @"Select you choice";
    NSString *actionTitle;
    
    if (self.selectedFriend.blocked) {
        title = [NSString stringWithFormat:@"Unblock %@ %@", self.selectedFriend.firstName, self.selectedFriend.lastName];
        //subtitle = @"";
        actionTitle = @"Unblock";
    } else {
        title = [NSString stringWithFormat:@"Block %@ %@", self.selectedFriend.firstName, self.selectedFriend.lastName];
        //subtitle = @"";
        actionTitle = @"Block";
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:actionTitle
                                                    otherButtonTitles:nil];
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex

{
    switch (buttonIndex) {
        case 0:
            
            if (self.selectedFriend.blocked) {
                [self unblockFriend:self.selectedFriend];
            } else {
                [self blockFriend:self.selectedFriend];
            }
            
            break;
        case 1:
            //cancel
            self.selectedFriend = nil;
            break;
        default:
            break;
    }
}

@end
