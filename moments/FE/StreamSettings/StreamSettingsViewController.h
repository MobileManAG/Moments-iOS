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
//  StreamSettingsViewController.h
//  moments
//
//  Created by MobileMan GmbH on 28/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum _SettingType {
    kSettingTypeUnknown = -1,
    kSettingTypeMinBitrate = 0,
    kSettingTypeMaxBitrate = 1,
    kSettingTypeSegmentsCount = 2,
    kSettingTypeSegmentsDuration = 3,
    kSettingTypeFramerate = 4,
    kSettingTypePreset = 5,
    kSettingTypeCodec = 6
    
} SettingType;

@interface StreamSettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) IBOutlet UIButton *backButton;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (assign) SettingType showingSettingsOfType;

- (IBAction)back:(id)sender;

@end
