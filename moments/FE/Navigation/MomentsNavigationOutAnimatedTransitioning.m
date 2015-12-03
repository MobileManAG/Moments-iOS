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
//  MomentsNavigationOutAnimatedTransitioning.m
//  moments
//
//  Created by MobileMan GmbH on 27/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "MomentsNavigationOutAnimatedTransitioning.h"

@implementation MomentsNavigationOutAnimatedTransitioning

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    float width;
    float height;
    CGRect fromStartFrame, fromEndFrame, toStartFrame, toEndFrame;
    
    height = [[UIScreen mainScreen] bounds].size.height;
    width = [[UIScreen mainScreen] bounds].size.width;
    
    fromStartFrame = CGRectMake(0, 0, width, height);
    fromEndFrame = CGRectMake(width, 0, width, height);
    
    toStartFrame = CGRectMake(-width, 0, width, height);
    toEndFrame = CGRectMake(0, 0, width, height);
    
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *fromView = [fromViewController view];
    fromView.frame = fromStartFrame;
    
    UIView *toView = [toViewController view];
    toView.frame = toStartFrame;
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:toView];
    
    [toView setUserInteractionEnabled: true];
    [fromView setUserInteractionEnabled: false];
    
    [UIView animateWithDuration:duration animations:^{
        fromView.frame = fromEndFrame;
        toView.frame = toEndFrame;
        
    } completion:^(BOOL finished) {
        
        
        [transitionContext completeTransition:finished];
    }];
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

@end
