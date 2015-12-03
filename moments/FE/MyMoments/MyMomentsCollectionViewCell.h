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
//  MyMomentsCollectionViewCell.h
//  moments
//
//  Created by MobileMan GmbH on 30/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Stream.h"

@protocol MyMomentsCollectionViewCellDelegate
- (void) didSelectWatchOf:(Stream*)stream;
- (void) didSelectMoreOn:(Stream*)stream onIndexPath:(NSIndexPath*)indexPath;
@end

@interface MyMomentsCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) Stream *stream;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, weak) NSObject<MyMomentsCollectionViewCellDelegate>* delegate;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, strong) IBOutlet UIButton *playButton;
@property (nonatomic, strong) IBOutlet UIButton *moreButton;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;

- (IBAction)play:(id)sender;
- (IBAction)more:(id)sender;

- (void)calculatePlayButtonPosition;

@end
