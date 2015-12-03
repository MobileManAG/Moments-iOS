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
//  CallViewController.m
//  moments
//
//  Created by MobileMan GmbH on 08/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "CallViewController.h"
#import "UIImageView+Haneke.h"
#import "fe_defines.h"
#import "ServiceFactory.h"
#import "UserService.h"
#import "User.h"
#import "Stream.h"

@implementation CallViewController

- (id) init {
    self = [super init];
    if(self){
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //user name
    NSMutableParagraphStyle *styleUserNameLabel = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [styleUserNameLabel setAlignment:NSTextAlignmentCenter];
    [styleUserNameLabel setLineBreakMode:NSLineBreakByWordWrapping];
    
    NSDictionary *dict1 = @{NSFontAttributeName:MOMENTS_FONT_DISPLAY_2,
                            NSParagraphStyleAttributeName:styleUserNameLabel};
    NSDictionary *dict2 = @{NSFontAttributeName:MOMENTS_FONT_TITLE_1,
                            NSParagraphStyleAttributeName:styleUserNameLabel};
    
    NSMutableAttributedString *userNameLabelString = [[NSMutableAttributedString alloc] init];
    [userNameLabelString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", [self.userInfoNotification objectForKey:@"userName"] ] attributes:dict1]];
    [userNameLabelString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Sharing live moments ..." attributes:dict2]];
    [self.userNameLabel setAttributedText:userNameLabelString];
    [self.userNameLabel setTextColor:[UIColor whiteColor]];
    [self.userNameLabel setNumberOfLines:0];
    [self.userNameLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [self.userNameLabel setBackgroundColor:[UIColor clearColor]];
    
    //title
    NSString *title = @"";
    if ([self.userInfoNotification objectForKey:@"title"]) {
        title = [self.userInfoNotification objectForKey:@"title"];
    }
    self.titleLabel.text = title;
    self.titleLabel.font = MOMENTS_FONT_TITLE_1;
    self.titleLabel.textColor = MOMENTS_COLOR_WHITE;
    
    //user
    self.userUID = [self.userInfoNotification objectForKey:@"userId"];
    
    //user image
    NSString *facebookId = [self.userInfoNotification objectForKey:@"facebookId"];
    
    self.userImageView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.userImageView.layer.cornerRadius = self.userImageView.frame.size.width/2;
    self.userImageView.clipsToBounds = YES;
    self.userImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.userImageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"call"];
    NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",@"https://graph.facebook.com/",facebookId,@"/picture?type=large"]];
    [self.userImageView hnk_setImageFromURL:imageUrl];
    
    //watch
    self.watchButton.backgroundColor = MOMENTS_COLOR_YELLOW_SEMITRANSPARENT;
    [self.watchButton setTitle:@"WATCH" forState:UIControlStateNormal];
    [self.watchButton setTitle:@"WATCH" forState:UIControlStateHighlighted];
    [[self.watchButton titleLabel] setTextColor:MOMENTS_COLOR_WHITE];
    [[self.watchButton titleLabel] setFont:MOMENTS_FONT_DISPLAY_2];
    [[self.watchButton titleLabel] setTextAlignment:NSTextAlignmentCenter];
    
    //pass
    self.passButton.backgroundColor = MOMENTS_COLOR_BLUE;
    [self.passButton setTitle:@"PASS" forState:UIControlStateNormal];
    [self.passButton setTitle:@"PASS" forState:UIControlStateHighlighted];
    [[self.passButton titleLabel] setTextColor:MOMENTS_COLOR_BLACK];
    [[self.passButton titleLabel] setFont:MOMENTS_FONT_DISPLAY_2];
    [[self.passButton titleLabel] setTextAlignment:NSTextAlignmentCenter];
    
    [self showThumbnail];
    
    [self playRingTone];
}

- (void) showThumbnail
{
    [[ServiceFactory userService] profile:self.userUID success:^(User *user) {
        NSLog(@"");
        
        //thumbnail
        NSURL *thumbnailURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/poster_%@", user.stream.thumbnailBaseUrl, user.stream.thumbnailFileName]];
        NSURLRequest* request = [NSURLRequest requestWithURL:thumbnailURL];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
                                   if (!error) {
                                       UIImage *thumbnail = [UIImage imageWithData:data];
                                       self.thumbnailView.image = thumbnail;
                                   }
                               }];
        
        
        
    } failure:^(NSError *error) {
        NSLog(@"user profile failure");
    }];
}

- (IBAction)pass:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate didSelectPass];
    }];
}

- (IBAction)watch:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate didSelectWatch:self.userUID];
    }];
}

- (void) playRingTone
{
    NSError *error;
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"Moments_30s" ofType:@"caf"];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSData* data = [NSData dataWithContentsOfURL:soundFileURL] ;
    self.player = [[AVAudioPlayer alloc] initWithData:data error:&error];
    
    if (!error) {
        self.player.delegate = self;
        self.player.numberOfLoops = 1;
        [self.player prepareToPlay];
        [self.player play];
    } else {
        NSLog(@"");
    }
    
}

#pragma  mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate didSelectPass];
    }];
}


- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"");
}

@end
