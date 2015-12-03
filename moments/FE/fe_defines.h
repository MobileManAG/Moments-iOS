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
//  fe_defines.h
//  moments
//
//  Created by MobileMan GmbH on 13/04/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#ifndef moments_fe_defines_h
#define moments_fe_defines_h

//IPAD

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

//IOS8

#define IS_IOS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

//USER THUMBNAIL

#define USER_THUMBNAIL_SIZE 48.0;

//FONTS

#define MOMENTS_FONT_DISPLAY_1 [UIFont fontWithName:@"SourceSansPro-Semibold" size:24]
#define MOMENTS_FONT_DISPLAY_2 [UIFont fontWithName:@"SourceSansPro-Semibold" size:34]
#define MOMENTS_FONT_TITLE_1 [UIFont fontWithName:@"SourceSansPro-Semibold" size:20]
#define MOMENTS_FONT_TITLE_2 [UIFont fontWithName:@"SourceSansPro-Regular" size:20]
#define MOMENTS_FONT_SUBHEAD_1 [UIFont fontWithName:@"SourceSansPro-Semibold" size:16]
#define MOMENTS_FONT_SUBHEAD_2 [UIFont fontWithName:@"SourceSansPro-Regular" size:16]
#define MOMENTS_FONT_CAPTION [UIFont fontWithName:@"SourceSansPro-Regular" size:12]
#define MOMENTS_FONT_CAPTION_BOLD [UIFont fontWithName:@"SourceSansPro-Semibold" size:12]
#define MOMENTS_FONT_BUTTON [UIFont fontWithName:@"SourceSansPro-Semibold" size:14]

//COLORS

#define MOMENTS_COLOR_RED [UIColor colorWithRed:0.988 green:0.502 blue:0.463 alpha:1.0] /*#fc8076*/
#define MOMENTS_COLOR_RED_SEMITRANSPARENT [UIColor colorWithRed:0.988 green:0.502 blue:0.463 alpha:0.84] /*#fc8076*/
#define MOMENTS_COLOR_YELLOW [UIColor colorWithRed:0.984 green:0.835 blue:0.267 alpha:1.0] /*#fbd544*/
#define MOMENTS_COLOR_YELLOW_SEMITRANSPARENT [UIColor colorWithRed:0.984 green:0.835 blue:0.267 alpha:0.84] /*#fbd544*/
#define MOMENTS_COLOR_GREEN [UIColor colorWithRed:0.106 green:0.694 blue:0.502 alpha:1] /*#1bb180*/
#define MOMENTS_COLOR_GREEN_SEMITRANSPARENT [UIColor colorWithRed:0.106 green:0.694 blue:0.502 alpha:0.84] /*#1bb180*/
#define MOMENTS_COLOR_BLUE_DARK [UIColor colorWithRed:0.008 green:0.906 blue:0.29 alpha:1] /*#2e74ab*/
#define MOMENTS_COLOR_BLUE [UIColor colorWithRed:0.365 green:0.62 blue:0.82 alpha:1] /*#5d9ed1*/
#define MOMENTS_COLOR_BLUE_SEMITRANSPARENT [UIColor colorWithRed:0.365 green:0.62 blue:0.82 alpha:0.84] /*#5d9ed1*/
#define MOMENTS_COLOR_WHITE [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:100.0]
#define MOMENTS_COLOR_WHITE_SEMITRANSPARENT [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.54]
#define MOMENTS_COLOR_WHITE_TRANSPARENT [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.12]
#define MOMENTS_COLOR_GREY_LIGHT [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.12]
#define MOMENTS_COLOR_GREY [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.54]
#define MOMENTS_COLOR_GREY_DARK [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.87]
#define MOMENTS_COLOR_BLACK [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]

//URLs

#define MOMENTS_APP_LINK @"http://www.server.com/myapp.html"
#define MOMENTS_INVITE_IMAGE_LINK @"http://server.com/FB_AppInvite_image_1200_628.png"
#define MOMENTS_TERMS_LINK @"http://server.com/?page_id=2883"
#define MOMENTS_PRIVACY_LINK @"http://server.com/?page_id=2878"

//STREAM METADATA
#define STREAM_METADATA_WATCHER_LIFETIME 4.5
#define STREAM_METADATA_WATCHERS_MAX_COUNT 3
#define STREAM_METADATA_COMMENT_LIFETIME 4.5
#define STREAM_METADATA_COMMENTS_MAX_COUNT 3

//BROADCASTER RECONNECT
#define BROADCASTER_RECONNECT_LABEL_LIFETIME 2

#endif
