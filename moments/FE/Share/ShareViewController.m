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
//  ShareViewController.m
//  moments
//
//  Created by MobileMan GmbH on 22/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "ShareViewController.h"
#import "ShareTableViewCell.h"

#import "fe_defines.h"

@implementation ShareViewController

- (id) init {
    self = [super init];
    if(self){
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.titleLabel.font = MOMENTS_FONT_DISPLAY_1;
    self.titleLabel.text = @"Share";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    return 5;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    //int section = indexPath.section;
    
    static NSString *cellIdentifier = @"ShareTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    ShareTableViewCell *shareTableViewCell = (ShareTableViewCell *)cell;
    if (shareTableViewCell == nil) {
        shareTableViewCell = [[ShareTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        
        
    }
    
    switch (row) {
        case 0:
            shareTableViewCell.nameLabel.text = @"Facebook";
            break;
        case 1:
            shareTableViewCell.nameLabel.text = @"Tumblr";
            break;
        case 2:
            shareTableViewCell.nameLabel.text = @"Twitter";
            break;
        case 3:
            shareTableViewCell.nameLabel.text = @"Reddit";
            break;
        case 4:
            shareTableViewCell.nameLabel.text = @"More";
            break;
        default:
            break;
    }
    
    if (row == 0) {
        shareTableViewCell.isFirstCell = YES;
    }
    
    cell = shareTableViewCell;
    //cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [cell setNeedsDisplay];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSInteger row = indexPath.row;
    //int section = indexPath.section;
    
    UIViewController *controllerToPush = nil;
    
    switch (row) {
        case 0:
            
            break;
        case 1:
            
            break;
        case 2:
            
            break;
        case 3:
            
            break;
        case 4:
            
            break;
            
        default:
            break;
    }
    
    if (controllerToPush != nil) {
        [self.navigationController pushViewController:controllerToPush animated:YES];
    }
    
}

@end
