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
//  SettingsOutAnimatedTransitioning.m
//  moments
//
//  Created by MobileMan GmbH on 23/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "SettingsOutAnimatedTransitioning.h"
#import "SettingsViewController.h"

@implementation SettingsOutAnimatedTransitioning

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    float width;
    float height;
    CGRect fromStartFrame, fromEndFrame, toStartFrame, toEndFrame;
    
    height = [[UIScreen mainScreen] bounds].size.height;
    width = [[UIScreen mainScreen] bounds].size.width;
    
    fromStartFrame = CGRectMake(0, 0, width, height);
    fromEndFrame = CGRectMake(0, -height, width, height);
    
    toStartFrame = CGRectMake(0, 0, width, height);
    toEndFrame = CGRectMake(0, 0, width, height);
    
    
    UINavigationController *fromViewController = (UINavigationController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UINavigationController *toViewController = (UINavigationController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIButton *settingsButton = nil;
    SettingsViewController *settingsViewController = (SettingsViewController*)[fromViewController.viewControllers lastObject];
    if ([settingsViewController isKindOfClass:[SettingsViewController class]]) {
        settingsButton = settingsViewController.settingsButton;
    }
    
    UIView *fromView = [fromViewController view];
    fromView.frame = fromStartFrame;
    
    UIView *toView = [toViewController view];
    toView.frame = toStartFrame;
    toView.alpha = 0;
    UIView *containerView = [transitionContext containerView];
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    [containerView insertSubview:toView belowSubview:fromView];
    if (settingsButton != nil) {
        [containerView addSubview:settingsButton];
        
        settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        [containerView addConstraint:[NSLayoutConstraint
                                      constraintWithItem:settingsButton
                                      attribute:NSLayoutAttributeCenterX
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:containerView
                                      attribute:NSLayoutAttributeCenterX
                                      multiplier:1.0
                                      constant:0.0]];
        
        [containerView addConstraint:[NSLayoutConstraint
                                      constraintWithItem:settingsButton
                                      attribute:NSLayoutAttributeTopMargin
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:containerView
                                      attribute:NSLayoutAttributeTopMargin
                                      multiplier:1.0
                                      constant:8.0]];
    }

    
    [toView setUserInteractionEnabled: true];
    [fromView setUserInteractionEnabled: false];
    
    [UIView animateWithDuration:duration animations:^{
        fromView.frame = fromEndFrame;
        toView.frame = toEndFrame;
        toView.alpha = 1;
    } completion:^(BOOL finished) {
        
        [transitionContext completeTransition:finished];
    }];
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

@end
