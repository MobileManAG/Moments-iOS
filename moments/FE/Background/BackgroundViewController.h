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
//  BackgroundViewController.h
//  moments
//
//  Created by MobileMan GmbH on 20/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "BroadcastService.h"

@interface BackgroundViewController : UIViewController


@property (nonatomic, strong) id<BroadcastService> broadcastService;
@property (strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) UIView *previewView;
@property (nonatomic, strong) CALayer *greyLayer;

- (void)showGrayLayer;
- (void)hideGreyLayer;
@end
