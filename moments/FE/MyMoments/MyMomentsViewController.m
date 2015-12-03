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
//  MyMomentsViewController.m
//  moments
//
//  Created by MobileMan GmbH on 30/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "MyMomentsViewController.h"
#import "fe_defines.h"
#import "Slice.h"
#import "UserSession.h"
#import "User.h"
#import "ServiceFactory.h"
#import "UserService.h"
#import "NSError+Util.h"
#import "UIImageView+Haneke.h"
#import "ViewerViewController.h"

@implementation MyMomentsViewController

- (id) init {
    self = [super init];
    if(self){
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleLabel.font = MOMENTS_FONT_DISPLAY_1;
    self.titleLabel.text = @"My Moments";
    
    UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.collectionView addSubview:refreshView];
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(updateStreamsList) forControlEvents:UIControlEventValueChanged];
    [refreshView addSubview:self.refreshControl];
    
    self.streamService = [ServiceFactory streamService:nil];
    [self.collectionView registerClass:[MyMomentsCollectionViewCell class] forCellWithReuseIdentifier:@"MyMomentsCollectionViewCell"];
    [self updateStreamsList];
    
}

- (IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) updateStreamsList
{
    UserSession *userSession = [[ServiceFactory userService] currentSession];
    if( userSession != nil){
        [[ServiceFactory userService] myMoments:userSession.user.uuid success:^(id<Slice> streams) {
            
            self.data = [streams.content mutableCopy];
            [self.collectionView reloadData];
            [self.spinner stopAnimating];
            
            if ([self.refreshControl isRefreshing]) {
                [self.refreshControl endRefreshing];
            }
            
        } failure:^(NSError *error) {
            
            NSLog(@"myMoments failure");
            
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
}

#pragma mark UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.data.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    MyMomentsCollectionViewCell *myMomentsCollectionViewCell = nil;
    
    static NSString *cellIdentifier = @"MyMomentsCollectionViewCell";
    myMomentsCollectionViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (myMomentsCollectionViewCell == nil) {
        myMomentsCollectionViewCell = [[MyMomentsCollectionViewCell alloc] init];
    }
    
    myMomentsCollectionViewCell.delegate = self;
    myMomentsCollectionViewCell.indexPath = indexPath;
    Stream *stream = [self.data objectAtIndex:row];
    if (stream) {
        myMomentsCollectionViewCell.stream = stream;
        if (myMomentsCollectionViewCell.thumbnailImageView.image == nil) {
            //myMomentsCollectionViewCell.thumbnailImageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"stream"];
            NSURL *thumbnailURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/poster_%@", stream.thumbnailBaseUrl, stream.thumbnailFileName]];
            [myMomentsCollectionViewCell.thumbnailImageView hnk_setImageFromURL:thumbnailURL];
        }
                
        if (stream.text.length > 0) {
            myMomentsCollectionViewCell.titleLabel.text = stream.text;
            myMomentsCollectionViewCell.titleLabel.hidden = NO;
            
        }
    }
    
    [myMomentsCollectionViewCell calculatePlayButtonPosition];
    return myMomentsCollectionViewCell;
}

#pragma mark MyMomentsCollectionViewCell

- (void) didSelectWatchOf:(Stream*)stream
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    ViewerViewController *viewerViewController = [storyboard instantiateViewControllerWithIdentifier:@"viewerViewController"];
    viewerViewController.stream = stream;
    viewerViewController.isArchivedStream = true;
    [self.navigationController pushViewController:viewerViewController animated:YES];
}

- (void) didSelectMoreOn:(Stream*)stream  onIndexPath:(NSIndexPath*)indexPath
{
    self.selectedStream = stream;
    self.selectedIndexPath = indexPath;
    if (IS_IOS_8_OR_LATER) {
        [self askDeleteStream:self.selectedStream onIndexPath:self.selectedIndexPath];
    } else {
        [self askDeleteStreamIOS7OnIndexPath:indexPath];
    }
    NSLog(@"");
}

- (void) askDeleteStream:(Stream*)stream onIndexPath:(NSIndexPath*)indexPath
{
    
    NSString *title = @"Delete";
    if (self.selectedStream.text.length > 0) {
        title = [NSString stringWithFormat:@"Delete %@", self.selectedStream.text];
    }
    
    UIAlertController* view = [UIAlertController alertControllerWithTitle:title
                                                                  message:nil//message:subtitle
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"Delete"
                         style:UIAlertActionStyleDestructive
                         handler:^(UIAlertAction * action)
                         {
                             [view dismissViewControllerAnimated:YES completion:nil];
                             [self showDeletionAlert];
                             
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
    CGRect cellRect = [self.collectionView cellForItemAtIndexPath:indexPath].frame;
    CGRect frame = [self.collectionView convertRect:cellRect toView:self.view];
    view.popoverPresentationController.sourceRect = frame;
    [self presentViewController:view animated:YES completion:nil];
}

- (void) askDeleteStreamIOS7OnIndexPath:(NSIndexPath*)indexPath
{
    NSString *title = @"Delete";
    if (self.selectedStream.text.length > 0) {
        title = [NSString stringWithFormat:@"Delete %@", self.selectedStream.text];
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Delete"
                                                    otherButtonTitles:nil];
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex

{
    switch (buttonIndex) {
        case 0:
            [self showDeletionAlert];
            break;
        case 1:
            //cancel
            self.selectedStream = nil;
            self.selectedIndexPath = nil;
            break;
        default:
            break;
    }
}

- (void) showDeletionAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:@"Are you sure you want to delete it?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch(buttonIndex) {
        case 0: //"No" pressed
            NSLog(@"");
            break;
        case 1: //"Yes" pressed
            [self deleteStream:self.selectedStream];
            break;
    }
}

- (void) deleteStream:(Stream*)stream
{
    if (stream) {
        [self.streamService deleteStream:stream text:@"" success:^(Stream *stream) {
            
            [self.data removeObject:stream];
            [self.collectionView reloadData];
            /*
            if (self.selectedIndexPath != nil) {
                [self.collectionView performBatchUpdates:^{
                    [self.data removeObject:stream];
                    [self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:self.selectedIndexPath]];
                } completion:^(BOOL finished) {
                    [self.collectionView reloadData];
                }];
            } else {
                [self updateStreamsList];
            }*/
            
        } failure:^(NSError *error) {
            NSLog(@"deleteStreamFailure");
        }];
    }
    
    self.selectedStream = nil;
}

@end
