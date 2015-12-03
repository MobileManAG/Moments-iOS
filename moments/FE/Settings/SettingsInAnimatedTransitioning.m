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
//  SettingsInAnimatedTransitioning.m
//  moments
//
//  Created by MobileMan GmbH on 23/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "SettingsInAnimatedTransitioning.h"

@implementation SettingsInAnimatedTransitioning

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    float width;
    float height;
    CGRect fromStartFrame, fromEndFrame, toStartFrame, toEndFrame;
    
    height = [[UIScreen mainScreen] bounds].size.height;
    width = [[UIScreen mainScreen] bounds].size.width;
    
    fromStartFrame = CGRectMake(0, 0, width, height);
    fromEndFrame = CGRectMake(0, 0, width, height);
    
    toStartFrame = CGRectMake(0, -height, width, height);
    toEndFrame = CGRectMake(0, 0, width, height);
    
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIButton *settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
    settingsButton.backgroundColor = [UIColor clearColor];
    UIImage *settingsButtonImage = [UIImage imageNamed:@"Logo_48.png"];
    [settingsButton setBackgroundImage:settingsButtonImage forState:UIControlStateNormal];
    [settingsButton setBackgroundImage:settingsButtonImage forState:UIControlStateHighlighted];
    
    UIView *fromView = [fromViewController view];
    fromView.frame = fromStartFrame;
    
    UIView *toView = [toViewController view];
    toView.frame = toStartFrame;
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:toView];
    [containerView addSubview:settingsButton];
    
    settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [containerView addConstraint:[NSLayoutConstraint
                              constraintWithItem:settingsButton
                              attribute:NSLayoutAttributeWidth
                              relatedBy:NSLayoutRelationEqual
                              toItem:nil
                              attribute:NSLayoutAttributeNotAnAttribute
                              multiplier:1
                              constant:48]];
    
    [containerView addConstraint:[NSLayoutConstraint
                                  constraintWithItem:settingsButton
                                  attribute:NSLayoutAttributeHeight
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:nil
                                  attribute:NSLayoutAttributeNotAnAttribute
                                  multiplier:1
                                  constant:48]];
    
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
                                  attribute:NSLayoutAttributeTop
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:containerView
                                  attribute:NSLayoutAttributeTop
                                  multiplier:1.0
                                  constant:8.0]];
    
    [toView setUserInteractionEnabled: true];
    [fromView setUserInteractionEnabled: false];
    
    [UIView animateWithDuration:duration animations:^{
        fromView.frame = fromEndFrame;
        fromView.alpha = 0;
        toView.frame = toEndFrame;
        
    } completion:^(BOOL finished) {
        [settingsButton removeFromSuperview];
        [transitionContext completeTransition:finished];
    }];
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

@end
