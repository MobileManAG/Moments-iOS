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
//  StreamSettingsViewController.m
//  moments
//
//  Created by MobileMan GmbH on 28/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "StreamSettingsViewController.h"
#import "VideoUtils.h"
#import "fe_defines.h"
#import "mom_defines.h"
@import AVFoundation;



@implementation StreamSettingsViewController

- (id) init {
    self = [super init];
    if(self){
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleLabel.font = MOMENTS_FONT_DISPLAY_1;
    self.titleLabel.text = @"Video settings";
    self.showingSettingsOfType = kSettingTypeUnknown;
}

- (IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 7;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    static NSString *cellIdentifier = @"StreamSettingsTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    
    cell.detailTextLabel.font = MOMENTS_FONT_DISPLAY_1;
    cell.detailTextLabel.textColor = MOMENTS_COLOR_BLACK;
    
    NSString *videoSessionPreset = [VideoUtils videoSessionPreset];
    NSString *videoCodec = [VideoUtils videoCodecProfile];
    
    switch (row) {
        case 0:
            cell.textLabel.text = @"Minimal bitrate";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f", [VideoUtils minBitrate]/1000];
            break;
        case 1:
            cell.textLabel.text = @"Maximal bitrate";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f", [VideoUtils maxBitrate]/1000];
            break;
        /*case 2:
            cell.textLabel.text = @"Video segments count";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%i", [VideoUtils videoSegmentsCount]];
            break;*/
        case 2:
            cell.textLabel.text = @"Video segments duration";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%i", [VideoUtils videoSegmentsDuration]];
            break;
        case 3:
            cell.textLabel.text = @"Video framerate";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%i", [VideoUtils videoFrameRate]];
            break;
        case 4:
            cell.textLabel.text = @"Video session preset";
            
            if ([videoSessionPreset isEqualToString:AVCaptureSessionPresetLow]) {
                cell.detailTextLabel.text = @"Low";
            } else if ([videoSessionPreset isEqualToString:AVCaptureSessionPresetMedium]) {
                cell.detailTextLabel.text = @"Medium";
            } else if ([videoSessionPreset isEqualToString:AVCaptureSessionPresetHigh]) {
                cell.detailTextLabel.text = @"High";
            } else if ([videoSessionPreset isEqualToString:AVCaptureSessionPreset352x288]) {
                cell.detailTextLabel.text = @"CIF";
            } else if ([videoSessionPreset isEqualToString:AVCaptureSessionPreset640x480]) {
                cell.detailTextLabel.text = @"VGA";
            } else if ([videoSessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
                cell.detailTextLabel.text = @"720p";
            } else if ([videoSessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
                cell.detailTextLabel.text = @"1080p";
            } else if ([videoSessionPreset isEqualToString:VIDEO_PRESET_AUTO]) {
                cell.detailTextLabel.text = @"Automatic";
            } else {
                cell.detailTextLabel.text = @"Automatic";
            }
            break;
        case 5:
            cell.textLabel.text = @"Video codec profile";
            
            if ([videoCodec isEqualToString:AVVideoProfileLevelH264Baseline30]) {
                cell.detailTextLabel.text = @"Baseline 30";
            } else if ([videoCodec isEqualToString:AVVideoProfileLevelH264Baseline31]) {
                cell.detailTextLabel.text = @"Baseline 31";
            } else if ([videoCodec isEqualToString:AVVideoProfileLevelH264Baseline41]) {
                cell.detailTextLabel.text = @"Baseline 41";
            } else if ([videoCodec isEqualToString:AVVideoProfileLevelH264BaselineAutoLevel]) {
                cell.detailTextLabel.text = @"Baseline Auto";
            } else if ([videoCodec isEqualToString:AVVideoProfileLevelH264Main30]) {
                cell.detailTextLabel.text = @"Main 30";
            } else if ([videoCodec isEqualToString:AVVideoProfileLevelH264Main31]) {
                cell.detailTextLabel.text = @"Main 31";
            } else if ([videoCodec isEqualToString:AVVideoProfileLevelH264Main32]) {
                cell.detailTextLabel.text = @"Main 32";
            } else if ([videoCodec isEqualToString:AVVideoProfileLevelH264Main41]) {
                cell.detailTextLabel.text = @"Main 41";
            } else if ([videoCodec isEqualToString:AVVideoProfileLevelH264MainAutoLevel]) {
                cell.detailTextLabel.text = @"Main Auto";
            } else if ([videoCodec isEqualToString:AVVideoProfileLevelH264High40]) {
                cell.detailTextLabel.text = @"High 40";
            } else if ([videoCodec isEqualToString:AVVideoProfileLevelH264High41]) {
                cell.detailTextLabel.text = @"High 41";
            } else if ([videoCodec isEqualToString:AVVideoProfileLevelH264HighAutoLevel]) {
                cell.detailTextLabel.text = @"High Auto";
            }
            
            break;
            
        default:
            break;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    [cell setNeedsDisplay];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSInteger row = indexPath.row;
    
    SettingType selectedSettingsType;
    
    switch (row) {
        case 0:
            selectedSettingsType = kSettingTypeMinBitrate;
            break;
        case 1:
            selectedSettingsType = kSettingTypeMaxBitrate;
            break;
        /*case 2:
            selectedSettingsType = kSettingTypeSegmentsCount;
            break;*/
        case 2:
            selectedSettingsType = kSettingTypeSegmentsDuration;
            break;
        case 3:
            selectedSettingsType = kSettingTypeFramerate;
            break;
        case 4:
            selectedSettingsType = kSettingTypePreset;
            break;
        case 5:
            selectedSettingsType = kSettingTypeCodec;
            break;
            
        default:
            break;
    }
    
    [self showSettingsFor:selectedSettingsType onIndexPath:indexPath];
    
}

- (NSArray*) getActionsForMinimalBitrate:(UIAlertController*) alertController {
    
    UIAlertAction* bitrate100 = [UIAlertAction
                         actionWithTitle:@"100"
                         style:UIAlertActionStyleDestructive
                         handler:^(UIAlertAction * action)
                         {
                             [VideoUtils setMinBitrate:(100 * 1000)];
                             [self.tableView reloadData];
                             [alertController dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    
    UIAlertAction* bitrate200 = [UIAlertAction
                                actionWithTitle:@"200"
                                style:UIAlertActionStyleDestructive
                                handler:^(UIAlertAction * action)
                                {
                                    [VideoUtils setMinBitrate:(200 * 1000)];
                                    [self.tableView reloadData];
                                    [alertController dismissViewControllerAnimated:YES completion:nil];
                                    
                                }];
    
    UIAlertAction* bitrate300 = [UIAlertAction
                                actionWithTitle:@"300"
                                style:UIAlertActionStyleDestructive
                                handler:^(UIAlertAction * action)
                                {
                                    [VideoUtils setMinBitrate:(300 * 1000)];
                                    [self.tableView reloadData];
                                    [alertController dismissViewControllerAnimated:YES completion:nil];
                                    
                                }];

    UIAlertAction* bitrate400 = [UIAlertAction
                         actionWithTitle:@"400"
                         style:UIAlertActionStyleDestructive
                         handler:^(UIAlertAction * action)
                         {
                             [VideoUtils setMinBitrate:(400 * 1000)];
                             [self.tableView reloadData];
                             [alertController dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    
    UIAlertAction* bitrate500 = [UIAlertAction
                                 actionWithTitle:@"500"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction * action)
                                 {
                                     [VideoUtils setMinBitrate:(500 * 1000)];
                                     [self.tableView reloadData];
                                     [alertController dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
    
    UIAlertAction* bitrate600 = [UIAlertAction
                                 actionWithTitle:@"600"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction * action)
                                 {
                                     [VideoUtils setMinBitrate:(600 * 1000)];
                                     [self.tableView reloadData];
                                     [alertController dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
    
    UIAlertAction* bitrate700 = [UIAlertAction
                                 actionWithTitle:@"700"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction * action)
                                 {
                                     [VideoUtils setMinBitrate:(700 * 1000)];
                                     [self.tableView reloadData];
                                     [alertController dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
    
    UIAlertAction* bitrate800 = [UIAlertAction
                                 actionWithTitle:@"800"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction * action)
                                 {
                                     [VideoUtils setMinBitrate:(800 * 1000)];
                                     [self.tableView reloadData];
                                     [alertController dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
    
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    double maxBitrate = [VideoUtils maxBitrate];
    
    [actions addObject:bitrate100];
    if (maxBitrate >= 200*1000) {
        [actions addObject:bitrate200];
    }
    if (maxBitrate >= 300*1000) {
        [actions addObject:bitrate300];
    }
    if (maxBitrate >= 400*1000) {
        [actions addObject:bitrate400];
    }
    if (maxBitrate >= 500*1000) {
        [actions addObject:bitrate500];
    }
    if (maxBitrate >= 600*1000) {
        [actions addObject:bitrate600];
    }
    if (maxBitrate >= 700*1000) {
        [actions addObject:bitrate700];
    }
    if (maxBitrate >= 800*1000) {
        [actions addObject:bitrate800];
    }
    
    return [NSArray arrayWithArray:actions];
}

- (NSArray*) getActionsForMaximalBitrate:(UIAlertController*) alertController {
    
    UIAlertAction* bitrate100 = [UIAlertAction
                                actionWithTitle:@"100"
                                style:UIAlertActionStyleDestructive
                                handler:^(UIAlertAction * action)
                                {
                                    [VideoUtils setMaxBitrate:(100 * 1000)];
                                    [self.tableView reloadData];
                                    [alertController dismissViewControllerAnimated:YES completion:nil];
                                    
                                }];
    
    UIAlertAction* bitrate200 = [UIAlertAction
                                actionWithTitle:@"200"
                                style:UIAlertActionStyleDestructive
                                handler:^(UIAlertAction * action)
                                {
                                    [VideoUtils setMaxBitrate:(200 * 1000)];
                                    [self.tableView reloadData];
                                    [alertController dismissViewControllerAnimated:YES completion:nil];
                                    
                                }];
    
    UIAlertAction* bitrate300 = [UIAlertAction
                                actionWithTitle:@"300"
                                style:UIAlertActionStyleDestructive
                                handler:^(UIAlertAction * action)
                                {
                                    [VideoUtils setMaxBitrate:(300 * 1000)];
                                    [self.tableView reloadData];
                                    [alertController dismissViewControllerAnimated:YES completion:nil];
                                    
                                }];
    
    UIAlertAction* bitrate400 = [UIAlertAction
                                 actionWithTitle:@"400"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction * action)
                                 {
                                     [VideoUtils setMaxBitrate:(400 * 1000)];
                                     [self.tableView reloadData];
                                     [alertController dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
    
    UIAlertAction* bitrate500 = [UIAlertAction
                                 actionWithTitle:@"500"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction * action)
                                 {
                                     [VideoUtils setMaxBitrate:(500 * 1000)];
                                     [self.tableView reloadData];
                                     [alertController dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
    
    UIAlertAction* bitrate600 = [UIAlertAction
                                 actionWithTitle:@"600"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction * action)
                                 {
                                     [VideoUtils setMaxBitrate:(600 * 1000)];
                                     [self.tableView reloadData];
                                     [alertController dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
    
    UIAlertAction* bitrate700 = [UIAlertAction
                                 actionWithTitle:@"700"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction * action)
                                 {
                                     [VideoUtils setMaxBitrate:(700 * 1000)];
                                     [self.tableView reloadData];
                                     [alertController dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
    
    UIAlertAction* bitrate800 = [UIAlertAction
                                 actionWithTitle:@"800"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction * action)
                                 {
                                     [VideoUtils setMaxBitrate:(800 * 1000)];
                                     [self.tableView reloadData];
                                     [alertController dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
    
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    double minBitrate = [VideoUtils minBitrate];
    
    [actions addObject:bitrate800];
    if (700*1000 >= minBitrate) {
        [actions addObject:bitrate700];
    }
    if (600*1000 >= minBitrate) {
        [actions addObject:bitrate600];
    }
    if (500*1000 >= minBitrate) {
        [actions addObject:bitrate500];
    }
    if (400*1000 >= minBitrate) {
        [actions addObject:bitrate400];
    }
    if (300*1000 >= minBitrate) {
        [actions addObject:bitrate300];
    }
    if (200*1000 >= minBitrate) {
        [actions addObject:bitrate200];
    }
    if (100*1000 >= minBitrate) {
        [actions addObject:bitrate100];
    }
    
    return [NSArray arrayWithArray:actions];
}

- (NSArray*) getActionsForSegmentsCount:(UIAlertController*) alertController {
    
    UIAlertAction* segmentsCount3 = [UIAlertAction
                                     actionWithTitle:@"3"
                                     style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction * action)
                                     {
                                         [VideoUtils setVideoSegmentsCount:3];
                                         [self.tableView reloadData];
                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
    
    UIAlertAction* segmentsCount4 = [UIAlertAction
                                     actionWithTitle:@"4"
                                     style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction * action)
                                     {
                                         [VideoUtils setVideoSegmentsCount:4];
                                         [self.tableView reloadData];
                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
    
    UIAlertAction* segmentsCount5 = [UIAlertAction
                                     actionWithTitle:@"5"
                                     style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction * action)
                                     {
                                         [VideoUtils setVideoSegmentsCount:5];
                                         [self.tableView reloadData];
                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
    
    UIAlertAction* segmentsCount6 = [UIAlertAction
                                     actionWithTitle:@"6"
                                     style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction * action)
                                     {
                                         [VideoUtils setVideoSegmentsCount:6];
                                         [self.tableView reloadData];
                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
    
    UIAlertAction* segmentsCount7 = [UIAlertAction
                                     actionWithTitle:@"7"
                                     style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction * action)
                                     {
                                         [VideoUtils setVideoSegmentsCount:7];
                                         [self.tableView reloadData];
                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
    
    UIAlertAction* segmentsCount8 = [UIAlertAction
                                     actionWithTitle:@"8"
                                     style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction * action)
                                     {
                                         [VideoUtils setVideoSegmentsCount:8];
                                         [self.tableView reloadData];
                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
    
    return [NSArray arrayWithObjects:segmentsCount3, segmentsCount4, segmentsCount5, segmentsCount6, segmentsCount7, segmentsCount8, nil];
}

- (NSArray*) getActionsForSegmentsDuration:(UIAlertController*) alertController {
    
    
    UIAlertAction* segmentsDuration3 = [UIAlertAction
                                     actionWithTitle:@"3"
                                     style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction * action)
                                     {
                                         [VideoUtils setVideoSegmentsDuration:3];
                                         [self.tableView reloadData];
                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
    
    UIAlertAction* segmentsDuration4 = [UIAlertAction
                                     actionWithTitle:@"4"
                                     style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction * action)
                                     {
                                         [VideoUtils setVideoSegmentsDuration:4];
                                         [self.tableView reloadData];
                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
    
    UIAlertAction* segmentsDuration5 = [UIAlertAction
                                     actionWithTitle:@"5"
                                     style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction * action)
                                     {
                                         [VideoUtils setVideoSegmentsDuration:5];
                                         [self.tableView reloadData];
                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
    
    UIAlertAction* segmentsDuration6 = [UIAlertAction
                                     actionWithTitle:@"6"
                                     style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction * action)
                                     {
                                         [VideoUtils setVideoSegmentsDuration:6];
                                         [self.tableView reloadData];
                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
    
    UIAlertAction* segmentsDuration7 = [UIAlertAction
                                     actionWithTitle:@"7"
                                     style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction * action)
                                     {
                                         [VideoUtils setVideoSegmentsDuration:7];
                                         [self.tableView reloadData];
                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
    
    UIAlertAction* segmentsDuration8 = [UIAlertAction
                                     actionWithTitle:@"8"
                                     style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction * action)
                                     {
                                         [VideoUtils setVideoSegmentsDuration:8];
                                         [self.tableView reloadData];
                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
    
    UIAlertAction* segmentsDuration9 = [UIAlertAction
                                        actionWithTitle:@"9"
                                        style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction * action)
                                        {
                                            [VideoUtils setVideoSegmentsDuration:9];
                                            [self.tableView reloadData];
                                            [alertController dismissViewControllerAnimated:YES completion:nil];
                                            
                                        }];
    
    UIAlertAction* segmentsDuration10 = [UIAlertAction
                                        actionWithTitle:@"10"
                                        style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction * action)
                                        {
                                            [VideoUtils setVideoSegmentsDuration:10];
                                            [self.tableView reloadData];
                                            [alertController dismissViewControllerAnimated:YES completion:nil];
                                            
                                        }];
    
    UIAlertAction* segmentsDuration11 = [UIAlertAction
                                         actionWithTitle:@"11"
                                         style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction * action)
                                         {
                                             [VideoUtils setVideoSegmentsDuration:11];
                                             [self.tableView reloadData];
                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                             
                                         }];
    
    UIAlertAction* segmentsDuration12 = [UIAlertAction
                                         actionWithTitle:@"12"
                                         style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction * action)
                                         {
                                             [VideoUtils setVideoSegmentsDuration:12];
                                             [self.tableView reloadData];
                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                             
                                         }];
    
    UIAlertAction* segmentsDuration13 = [UIAlertAction
                                         actionWithTitle:@"13"
                                         style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction * action)
                                         {
                                             [VideoUtils setVideoSegmentsDuration:13];
                                             [self.tableView reloadData];
                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                             
                                         }];
    
    UIAlertAction* segmentsDuration14 = [UIAlertAction
                                         actionWithTitle:@"14"
                                         style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction * action)
                                         {
                                             [VideoUtils setVideoSegmentsDuration:14];
                                             [self.tableView reloadData];
                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                             
                                         }];
    
    UIAlertAction* segmentsDuration15 = [UIAlertAction
                                         actionWithTitle:@"15"
                                         style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction * action)
                                         {
                                             [VideoUtils setVideoSegmentsDuration:15];
                                             [self.tableView reloadData];
                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                             
                                         }];
    
    return [NSArray arrayWithObjects:segmentsDuration3, segmentsDuration4, segmentsDuration5, segmentsDuration6, segmentsDuration7, segmentsDuration8, segmentsDuration9, segmentsDuration10, segmentsDuration11, segmentsDuration12, segmentsDuration13, segmentsDuration14, segmentsDuration15, nil];
}

- (NSArray*) getActionsForFramerate:(UIAlertController*) alertController {
    
    UIAlertAction* framerate15 = [UIAlertAction
                                        actionWithTitle:@"15"
                                        style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction * action)
                                        {
                                            [VideoUtils setVideoFrameRate:15];
                                            [self.tableView reloadData];
                                            [alertController dismissViewControllerAnimated:YES completion:nil];
                                            
                                        }];
    
    UIAlertAction* framerate20 = [UIAlertAction
                                        actionWithTitle:@"20"
                                        style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction * action)
                                        {
                                            [VideoUtils setVideoFrameRate:20];
                                            [self.tableView reloadData];
                                            [alertController dismissViewControllerAnimated:YES completion:nil];
                                            
                                        }];
    
    UIAlertAction* framerate25 = [UIAlertAction
                                        actionWithTitle:@"25"
                                        style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction * action)
                                        {
                                            [VideoUtils setVideoFrameRate:25];
                                            [self.tableView reloadData];
                                            [alertController dismissViewControllerAnimated:YES completion:nil];
                                            
                                        }];
    
    UIAlertAction* framerate30 = [UIAlertAction
                                        actionWithTitle:@"30"
                                        style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction * action)
                                        {
                                            [VideoUtils setVideoFrameRate:30];
                                            [self.tableView reloadData];
                                            [alertController dismissViewControllerAnimated:YES completion:nil];
                                            
                                        }];
    
    return [NSArray arrayWithObjects:framerate15, framerate20, framerate25, framerate30, nil];
}

- (NSArray*) getActionsForSessionPreset:(UIAlertController*) alertController {

    UIAlertAction* videoSessionPresetLow = [UIAlertAction
                                            actionWithTitle:@"Low (suitable for sharing over 3G)"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoSessionPreset:AVCaptureSessionPresetLow];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoSessionPresetMedium = [UIAlertAction
                                            actionWithTitle:@"Medium (suitable for sharing over WiFi)"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoSessionPreset:AVCaptureSessionPresetMedium];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoSessionPresetHigh = [UIAlertAction
                                            actionWithTitle:@"High (high quality video and audio)"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoSessionPreset:AVCaptureSessionPresetHigh];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoSessionPresetCIF = [UIAlertAction
                                            actionWithTitle:@"352x288 (CIF quality)"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoSessionPreset:AVCaptureSessionPreset352x288];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoSessionPresetVGA = [UIAlertAction
                                            actionWithTitle:@"640x480 (VGA quality)"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoSessionPreset:AVCaptureSessionPreset640x480];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoSessionPreset720p = [UIAlertAction
                                            actionWithTitle:@"1280x720 (720p quality)"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoSessionPreset:AVCaptureSessionPreset1280x720];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoSessionPreset1080p = [UIAlertAction
                                            actionWithTitle:@"1920x1080 (1080p full HD quality)"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoSessionPreset:AVCaptureSessionPreset1920x1080];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoSessionPresetAuto = [UIAlertAction
                                            actionWithTitle:@"Automatic"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoSessionPreset:VIDEO_PRESET_AUTO];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    return [NSArray arrayWithObjects:videoSessionPresetLow, videoSessionPresetMedium, videoSessionPresetHigh, videoSessionPresetCIF, videoSessionPresetVGA, videoSessionPreset720p, videoSessionPreset1080p, videoSessionPresetAuto, nil];
}

- (NSArray*) getActionsForCodec:(UIAlertController*) alertController {
    
    UIAlertAction* videoCodecBaseline30 = [UIAlertAction
                                            actionWithTitle:@"Baseline 30"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264Baseline30];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoCodecBaseline31 = [UIAlertAction
                                            actionWithTitle:@"Baseline 31"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264Baseline31];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoCodecBaseline41 = [UIAlertAction
                                            actionWithTitle:@"Baseline 41"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264Baseline41];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoCodecBaselineAuto = [UIAlertAction
                                            actionWithTitle:@"Baseline Auto"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264BaselineAutoLevel];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoCodecMain30 = [UIAlertAction
                                            actionWithTitle:@"Main 30"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264Main30];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoCodecMain31 = [UIAlertAction
                                            actionWithTitle:@"Main 31"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264Main31];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoCodecMain32 = [UIAlertAction
                                            actionWithTitle:@"Main 32"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264Main32];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoCodecMain41 = [UIAlertAction
                                            actionWithTitle:@"Main 41"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264Main41];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoCodecMainAuto = [UIAlertAction
                                            actionWithTitle:@"Main Auto"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264MainAutoLevel];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];

    UIAlertAction* videoCodecHigh40 = [UIAlertAction
                                            actionWithTitle:@"High 40"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264High40];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoCodecHigh41 = [UIAlertAction
                                            actionWithTitle:@"High 41"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264High41];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    UIAlertAction* videoCodecHighAuto = [UIAlertAction
                                            actionWithTitle:@"High Auto"
                                            style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                                            {
                                                [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264HighAutoLevel];
                                                [self.tableView reloadData];
                                                [alertController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }];
    
    return [NSArray arrayWithObjects:videoCodecBaseline30, videoCodecBaseline31, videoCodecBaseline41, videoCodecBaselineAuto, videoCodecMain30, videoCodecMain31, videoCodecMain32, videoCodecMain41, videoCodecMainAuto, videoCodecHigh40, videoCodecHigh41, videoCodecHighAuto, nil];
}

- (void) showSettingsFor:(SettingType)type onIndexPath:(NSIndexPath*)indexPath
{
    
    NSString *title = @"";
    
    switch (type) {
        case kSettingTypeMinBitrate:
            title = @"Minimal bitrate";
            break;
        case kSettingTypeMaxBitrate:
            title = @"Maximal bitrate";
            break;
        case kSettingTypeSegmentsCount:
            title = @"Video segments count";
            break;
        case kSettingTypeSegmentsDuration:
            title = @"Video segments duration";
            break;
        case kSettingTypeFramerate:
            title = @"Video framerate";
            break;
        case kSettingTypePreset:
            title = @"Video session preset";
            break;
        case kSettingTypeCodec:
            title = @"Video codec profile";
            break;
        default:
            break;
    }
    
    if (IS_IOS_8_OR_LATER) {
        
        UIAlertController* view = [UIAlertController alertControllerWithTitle:title
                                                                      message:nil
                                                               preferredStyle:UIAlertControllerStyleAlert];
        switch (type) {
            case kSettingTypeMinBitrate:
                for (UIAlertAction *action in [self getActionsForMinimalBitrate:view]) {
                    [view addAction:action];
                }
                break;
            case kSettingTypeMaxBitrate:
                for (UIAlertAction *action in [self getActionsForMaximalBitrate:view]) {
                    [view addAction:action];
                }
                break;
            case kSettingTypeSegmentsCount:
                for (UIAlertAction *action in [self getActionsForSegmentsCount:view]) {
                    [view addAction:action];
                }
                break;
            case kSettingTypeSegmentsDuration:
                for (UIAlertAction *action in [self getActionsForSegmentsDuration:view]) {
                    [view addAction:action];
                }
                break;
            case kSettingTypeFramerate:
                for (UIAlertAction *action in [self getActionsForFramerate:view]) {
                    [view addAction:action];
                }
                break;
            case kSettingTypePreset:
                for (UIAlertAction *action in [self getActionsForSessionPreset:view]) {
                    [view addAction:action];
                }
                break;
            case kSettingTypeCodec:
                for (UIAlertAction *action in [self getActionsForCodec:view]) {
                    [view addAction:action];
                }
                break;
            default:
                break;
        }
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
                                 {
                                     [view dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
        
        
        [view addAction:cancel];
        view.popoverPresentationController.sourceView = self.view;
        CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
        view.popoverPresentationController.sourceRect = cellRect;
        [self presentViewController:view animated:YES completion:nil];
        
    } else {
        
        UIActionSheet *actionSheet;
        
        switch (type) {
            case kSettingTypeMinBitrate:
                self.showingSettingsOfType = kSettingTypeMinBitrate;
                actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                          delegate:self
                                                 cancelButtonTitle:nil
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:nil];
                
                double maxBitrate = [VideoUtils maxBitrate];
                
                [actionSheet addButtonWithTitle:@"bitrate100"];
                if (maxBitrate >= 200*1000) {
                    [actionSheet addButtonWithTitle:@"bitrate200"];
                }
                if (maxBitrate >= 300*1000) {
                    [actionSheet addButtonWithTitle:@"bitrate300"];
                }
                if (maxBitrate >= 400*1000) {
                    [actionSheet addButtonWithTitle:@"bitrate400"];
                }
                if (maxBitrate >= 500*1000) {
                    [actionSheet addButtonWithTitle:@"bitrate500"];
                }
                if (maxBitrate >= 600*1000) {
                    [actionSheet addButtonWithTitle:@"bitrate600"];
                }
                if (maxBitrate >= 700*1000) {
                    [actionSheet addButtonWithTitle:@"bitrate700"];
                }
                if (maxBitrate >= 800*1000) {
                    [actionSheet addButtonWithTitle:@"bitrate800"];
                }
                
                break;
            case kSettingTypeMaxBitrate:
                self.showingSettingsOfType = kSettingTypeMaxBitrate;
                actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                          delegate:self
                                                 cancelButtonTitle:nil
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:nil];
                
                double minBitrate = [VideoUtils minBitrate];
                
                [actionSheet addButtonWithTitle:@"bitrate800"];
                if (700*1000 >= minBitrate) {
                    [actionSheet addButtonWithTitle:@"bitrate700"];
                }
                if (600*1000 >= minBitrate) {
                    [actionSheet addButtonWithTitle:@"bitrate600"];
                }
                if (500*1000 >= minBitrate) {
                    [actionSheet addButtonWithTitle:@"bitrate500"];
                }
                if (400*1000 >= minBitrate) {
                    [actionSheet addButtonWithTitle:@"bitrate400"];
                }
                if (300*1000 >= minBitrate) {
                    [actionSheet addButtonWithTitle:@"bitrate300"];
                }
                if (200*1000 >= minBitrate) {
                    [actionSheet addButtonWithTitle:@"bitrate200"];
                }
                if (100*1000 >= minBitrate) {
                    [actionSheet addButtonWithTitle:@"bitrate100"];
                }
                
                break;
            case kSettingTypeSegmentsCount:
                self.showingSettingsOfType = kSettingTypeSegmentsCount;
                actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                          delegate:self
                                                 cancelButtonTitle:nil
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:
                               @"3",
                               @"4",
                               @"5",
                               @"6",
                               @"7",
                               @"8",
                               nil];
                
                break;
            case kSettingTypeSegmentsDuration:
                self.showingSettingsOfType = kSettingTypeSegmentsDuration;
                actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                          delegate:self
                                                 cancelButtonTitle:nil
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:
                               
                               @"3",
                               @"4",
                               @"5",
                               @"6",
                               @"7",
                               @"8",
                               @"9",
                               @"10",
                               @"11",
                               @"12",
                               @"13",
                               @"14",
                               @"15",
                               nil];
                
                break;
            case kSettingTypeFramerate:
                self.showingSettingsOfType = kSettingTypeFramerate;
                actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                          delegate:self
                                                 cancelButtonTitle:nil
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:
                               @"15",
                               @"20",
                               @"25",
                               @"30",
                               nil];
                
                break;
            case kSettingTypePreset:
                self.showingSettingsOfType = kSettingTypePreset;
                actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                          delegate:self
                                                 cancelButtonTitle:nil
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:
                               @"Low (suitable for sharing over 3G)",
                               @"Medium (suitable for sharing over WiFi)",
                               @"High (high quality video and audio)",
                               @"352x288 (CIF quality)",
                               @"640x480 (VGA quality)",
                               @"1280x720 (720p quality)",
                               @"1920x1080 (1080p full HD quality)",
                               @"Automatic",
                               nil];
                
                break;
            case kSettingTypeCodec:
                self.showingSettingsOfType = kSettingTypeCodec;
                actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                          delegate:self
                                                 cancelButtonTitle:nil
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:
                               @"Baseline 30",
                               @"Baseline 31",
                               @"Baseline 41",
                               @"Baseline Auto",
                               @"Main 30",
                               @"Main 31",
                               @"Main 32",
                               @"Main 41",
                               @"Main Auto",
                               @"High 40",
                               @"High 41",
                               @"High Auto",
                               nil];
                
                break;
            default:
                break;
        }
        
        if (actionSheet) {
            [actionSheet showInView:self.view];
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (self.showingSettingsOfType) {
        case kSettingTypeMinBitrate:
            
            switch (buttonIndex) {
                case 0:
                    [VideoUtils setMinBitrate:(100 * 1000)];
                    break;
                case 1:
                    [VideoUtils setMinBitrate:(200 * 1000)];
                    break;
                case 2:
                    [VideoUtils setMinBitrate:(300 * 1000)];
                    break;
                case 3:
                    [VideoUtils setMinBitrate:(400 * 1000)];
                    break;
                case 4:
                    [VideoUtils setMinBitrate:(500 * 1000)];
                    break;
                case 5:
                    [VideoUtils setMinBitrate:(600 * 1000)];
                    break;
                case 6:
                    [VideoUtils setMinBitrate:(700 * 1000)];
                    break;
                case 7:
                    [VideoUtils setMinBitrate:(800 * 1000)];
                    break;
                default:
                    break;
            }
            
            break;
        case kSettingTypeMaxBitrate:
            
            switch (buttonIndex) {
                case 0:
                    [VideoUtils setMaxBitrate:(800 * 1000)];
                    break;
                case 1:
                    [VideoUtils setMaxBitrate:(700 * 1000)];
                    break;
                case 2:
                    [VideoUtils setMaxBitrate:(600 * 1000)];
                    break;
                case 3:
                    [VideoUtils setMaxBitrate:(500 * 1000)];
                    break;
                case 4:
                    [VideoUtils setMaxBitrate:(400 * 1000)];
                    break;
                case 5:
                    [VideoUtils setMaxBitrate:(300 * 1000)];
                    break;
                case 6:
                    [VideoUtils setMaxBitrate:(200 * 1000)];
                    break;
                case 7:
                    [VideoUtils setMaxBitrate:(100 * 1000)];
                    break;
                default:
                    break;
            }
            
            break;
        case kSettingTypeSegmentsCount:
            
            switch (buttonIndex) {
                case 0:
                    [VideoUtils setVideoSegmentsCount:3];
                    break;
                case 1:
                    [VideoUtils setVideoSegmentsCount:4];
                    break;
                case 2:
                    [VideoUtils setVideoSegmentsCount:5];
                    break;
                case 3:
                    [VideoUtils setVideoSegmentsCount:6];
                    break;
                case 4:
                    [VideoUtils setVideoSegmentsCount:7];
                    break;
                case 5:
                    [VideoUtils setVideoSegmentsCount:8];
                    break;
                default:
                    break;
            }
            
            break;
        case kSettingTypeSegmentsDuration:
            
            switch (buttonIndex) {
                
                case 0:
                    [VideoUtils setVideoSegmentsDuration:3];
                    break;
                case 1:
                    [VideoUtils setVideoSegmentsDuration:4];
                    break;
                case 2:
                    [VideoUtils setVideoSegmentsDuration:5];
                    break;
                case 3:
                    [VideoUtils setVideoSegmentsDuration:6];
                    break;
                case 4:
                    [VideoUtils setVideoSegmentsDuration:7];
                    break;
                case 5:
                    [VideoUtils setVideoSegmentsDuration:8];
                    break;
                case 6:
                    [VideoUtils setVideoSegmentsDuration:9];
                    break;
                case 7:
                    [VideoUtils setVideoSegmentsDuration:10];
                    break;
                case 8:
                    [VideoUtils setVideoSegmentsDuration:11];
                    break;
                case 9:
                    [VideoUtils setVideoSegmentsDuration:12];
                    break;
                case 10:
                    [VideoUtils setVideoSegmentsDuration:13];
                    break;
                case 11:
                    [VideoUtils setVideoSegmentsDuration:14];
                    break;
                case 12:
                    [VideoUtils setVideoSegmentsDuration:15];
                    break;
                default:
                    break;
            }
            
            break;
        case kSettingTypeFramerate:
            
            switch (buttonIndex) {
                case 0:
                    [VideoUtils setVideoFrameRate:15];
                    break;
                case 1:
                    [VideoUtils setVideoFrameRate:20];
                    break;
                case 2:
                    [VideoUtils setVideoFrameRate:25];
                    break;
                case 3:
                    [VideoUtils setVideoFrameRate:30];
                    break;
                default:
                    break;
            }
            
            break;
        case kSettingTypePreset:
            
            switch (buttonIndex) {
                case 0:
                    [VideoUtils setVideoSessionPreset:AVCaptureSessionPresetLow];
                    break;
                case 1:
                    [VideoUtils setVideoSessionPreset:AVCaptureSessionPresetMedium];
                    break;
                case 2:
                    [VideoUtils setVideoSessionPreset:AVCaptureSessionPresetHigh];
                    break;
                case 3:
                    [VideoUtils setVideoSessionPreset:AVCaptureSessionPreset352x288];
                    break;
                case 4:
                    [VideoUtils setVideoSessionPreset:AVCaptureSessionPreset640x480];
                    break;
                case 5:
                    [VideoUtils setVideoSessionPreset:AVCaptureSessionPreset1280x720];
                    break;
                case 6:
                    [VideoUtils setVideoSessionPreset:AVCaptureSessionPreset1920x1080];
                    break;
                case 7:
                    [VideoUtils setVideoSessionPreset:VIDEO_PRESET_AUTO];
                    break;
                default:
                    break;
            }
            
            break;
        case kSettingTypeCodec:
            
            switch (buttonIndex) {
                case 0:
                    [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264Baseline30];
                    break;
                case 1:
                    [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264Baseline31];
                    break;
                case 2:
                    [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264Baseline41];
                    break;
                case 3:
                    [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264BaselineAutoLevel];
                    break;
                case 4:
                    [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264Main30];
                    break;
                case 5:
                    [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264Main31];
                    break;
                case 6:
                    [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264Main32];
                    break;
                case 7:
                    [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264Main41];
                    break;
                case 8:
                    [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264MainAutoLevel];
                    break;
                case 9:
                    [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264High40];
                    break;
                case 10:
                    [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264High41];
                    break;
                case 11:
                    [VideoUtils setVideoCodecProfile:AVVideoProfileLevelH264HighAutoLevel];
                    break;
                default:
                    break;
            }
            
            break;
        default:
            break;
    }
    
    [self.tableView reloadData];
}

@end
