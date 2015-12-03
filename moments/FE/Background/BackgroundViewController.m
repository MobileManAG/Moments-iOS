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
//  BackgroundViewController.m
//  moments
//
//  Created by MobileMan GmbH on 20/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "BackgroundViewController.h"
#import "ServiceFactory.h"
#import "fe_defines.h"

@implementation BackgroundViewController

- (id) init {
    self = [super init];
    if(self){
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.previewView = [[UIView alloc] init];
    self.previewView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.previewView];
    
    [self initCaptureSession];
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.previewView.frame = self.view.frame;
    CGRect previewViewFrame = self.previewView.frame;
    if (self.previewLayer) {
        self.previewLayer.frame = previewViewFrame;
    }
    self.greyLayer.frame = previewViewFrame;
}

- (void) initCaptureSession
{
    self.broadcastService = [ServiceFactory broadcastService];
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.broadcastService.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];   
    [self.previewView.layer addSublayer:self.previewLayer];
    
    self.greyLayer = [CALayer layer];
    self.greyLayer.backgroundColor = (MOMENTS_COLOR_BLUE_SEMITRANSPARENT).CGColor;
    [self.previewView.layer addSublayer:self.greyLayer];
    
    [self.broadcastService.session startRunning];
}

- (void) showGrayLayer
{
    self.greyLayer.backgroundColor = (MOMENTS_COLOR_BLUE_SEMITRANSPARENT).CGColor;
}

- (void) hideGreyLayer
{
    self.greyLayer.backgroundColor = nil;
}

@end
