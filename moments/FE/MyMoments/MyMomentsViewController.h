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
//  MyMomentsViewController.h
//  moments
//
//  Created by MobileMan GmbH on 30/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyMomentsCollectionViewCell.h"
#import "Stream.h"
#import "StreamService.h"

@interface MyMomentsViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, MyMomentsCollectionViewCellDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) id<StreamService> streamService;
@property (nonatomic, strong) NSArray *streams;
@property (nonatomic, strong) Stream *selectedStream;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@property (nonatomic, strong) IBOutlet UIButton *backButton;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic, strong) NSMutableArray *data;

- (IBAction)back:(id)sender;

@end
