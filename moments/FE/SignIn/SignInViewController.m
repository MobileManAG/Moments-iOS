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
//  SignInViewController.m
//  moments
//
//  Created by MobileMan GmbH on 13/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import <FBSDKLoginKit/FBSDKLoginConstants.h>
#import "SignInViewController.h"
#import "ServiceFactory.h"
#import "UserService.h"
#import "FriendsViewController.h"
#import "fe_defines.h"
#import "WebViewController.h"
#import "Haneke.h"
#import "mom_notifications.h"

@implementation SignInViewController

- (id) init {
    self = [super init];
    if(self){
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Sign in";
    [self.navigationItem setHidesBackButton:YES];
    self.view.backgroundColor = [UIColor clearColor];
    
    //Sign in
    NSMutableParagraphStyle *styleSignInButton = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [styleSignInButton setAlignment:NSTextAlignmentCenter];
    [styleSignInButton setLineBreakMode:NSLineBreakByWordWrapping];
    
    NSDictionary *dict = @{NSUnderlineStyleAttributeName:@(NSUnderlineStyleNone),
                            NSFontAttributeName:MOMENTS_FONT_TITLE_1,
                            NSParagraphStyleAttributeName:styleSignInButton};
    
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] init];
    [attString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Log in with Facebook" attributes:dict]];
    [self.signInButton setAttributedTitle:attString forState:UIControlStateNormal];
    [[self.signInButton titleLabel] setTextColor:MOMENTS_COLOR_GREY];
    [[self.signInButton titleLabel] setNumberOfLines:0];
    [[self.signInButton titleLabel] setLineBreakMode:NSLineBreakByWordWrapping];
    [self.signInButton setBackgroundColor:MOMENTS_COLOR_WHITE_SEMITRANSPARENT];
    
    //Terms
    NSMutableParagraphStyle *styleTermsButton = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [styleTermsButton setAlignment:NSTextAlignmentCenter];
    [styleTermsButton setLineBreakMode:NSLineBreakByWordWrapping];
    
    NSDictionary *dict1 = @{NSUnderlineStyleAttributeName:@(NSUnderlineStyleNone),
                            NSFontAttributeName:MOMENTS_FONT_CAPTION,
                            NSParagraphStyleAttributeName:styleTermsButton};
    NSDictionary *dict2 = @{NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle),
                            NSFontAttributeName:MOMENTS_FONT_CAPTION,
                            NSParagraphStyleAttributeName:styleTermsButton};
    
    NSMutableAttributedString *termsAttString = [[NSMutableAttributedString alloc] init];
    [termsAttString appendAttributedString:[[NSAttributedString alloc] initWithString:@"By continuing you indicate to have read and agreed on the " attributes:dict1]];
    [termsAttString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Terms of Service" attributes:dict2]];
    [self.termsButton setAttributedTitle:termsAttString forState:UIControlStateNormal];
    [[self.termsButton titleLabel] setTextColor:[UIColor whiteColor]];
    [[self.termsButton titleLabel] setNumberOfLines:0];
    [[self.termsButton titleLabel] setLineBreakMode:NSLineBreakByWordWrapping];
    [self.termsButton setBackgroundColor:[UIColor clearColor]];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(friendBroadcastStarted:) name:MOMFriendBroadcastStartedNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MOMFriendBroadcastStartedNotification object:nil];
    
}

- (void) friendBroadcastStarted:(NSNotification *)notification
{
    self.notificationReceived = notification;
}

- (void) updateButtonText:(NSString*)text
{
    NSMutableParagraphStyle *styleSignInButton = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [styleSignInButton setAlignment:NSTextAlignmentCenter];
    [styleSignInButton setLineBreakMode:NSLineBreakByWordWrapping];
    
    NSDictionary *dict = @{NSUnderlineStyleAttributeName:@(NSUnderlineStyleNone),
                           NSFontAttributeName:MOMENTS_FONT_TITLE_1,
                           NSParagraphStyleAttributeName:styleSignInButton};
    
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] init];
    [attString appendAttributedString:[[NSAttributedString alloc] initWithString:text attributes:dict]];
    [self.signInButton setAttributedTitle:attString forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) showFriends
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    FriendsViewController *friendsViewController = [storyboard instantiateViewControllerWithIdentifier:@"friendsViewController"];
    friendsViewController.isCommingFromSignIn = YES;
    [self.navigationController pushViewController:friendsViewController animated:YES];
}

- (IBAction)signIn:(id)sender
{
    
    [self updateButtonText:@"Logging in..."];
    [[ServiceFactory userService] signin:^(User *session) {
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 140, 140)];
        imageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"thumbnail"];
        [imageView hnk_setImageFromURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",@"https://graph.facebook.com/",session.facebookID,@"/picture?type=large"]]];
        
        [self updateButtonText:@"Success"];
        //[self.navigationController popViewControllerAnimated:YES];
        NSNumber *signedInOn = session.signedInOn;
        if (signedInOn == nil) {
            [self showFriends];
        } else {
            
            [self.navigationController popToRootViewControllerAnimated:YES];
            [self.delegate didLoginAndReceivedNotification:self.notificationReceived];
        }
        
    } failure:^(NSError *error) {
        if ([error.domain isEqualToString:FBSDKLoginErrorDomain]) {
            NSString * message = [error.userInfo objectForKey:NSLocalizedDescriptionKey];
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"kLabelFacebook", "kLabelFacebook")  message:message delegate:self cancelButtonTitle:NSLocalizedString(@"kLabelOk", "kLabelOk") otherButtonTitles:nil];
            [alertView show];
        } else if ([error.domain isEqualToString:MomentsErrorDomain]) {
            if (error.code == kErrorCodeFBSignInCancelled) {
                
            }
        }
        
        [self updateButtonText:@"Try again"];
    }];
  
}

- (IBAction)terms:(id)sender
{
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:MOMENTS_TERMS_LINK]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    WebViewController *webViewController = [storyboard instantiateViewControllerWithIdentifier:@"webViewController"];
    webViewController.titleText = @"Terms of Service";
    webViewController.url = [NSURL URLWithString:MOMENTS_TERMS_LINK];
    [self.navigationController pushViewController:webViewController animated:YES];
}

@end
