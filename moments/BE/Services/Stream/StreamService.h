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
//  StreamService.h
//  moments
//
//  Created by MobileMan GmbH on 28.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

@protocol Slice, StreamServiceDelegate;
@class Stream, StreamMetadata, Location;

@protocol StreamService <NSObject>

@property (nonatomic, weak) id<StreamServiceDelegate> delegate;

- (void)liveBroadcasts:(void (^)(id<Slice> streams))success failure:(void (^)(NSError *error))failure;
- (void)joinBroadcast:(Stream *)stream success:(void (^)(StreamMetadata * metadata))success failure:(void (^)(NSError *error))failure;
- (void)leaveBroadcast:(Stream *)stream success:(void (^)(StreamMetadata * metadata))success failure:(void (^)(NSError *error))failure;
- (void)postComment:(Stream *)stream text:(NSString *)text success:(void (^)(StreamMetadata * metadata))success failure:(void (^)(NSError *error))failure;
- (void)deleteStream:(Stream *)stream text:(NSString *)text success:(void (^)(Stream * stream))success failure:(void (^)(NSError *error))failure;

@end

@protocol StreamServiceDelegate <NSObject>

@optional

- (void)streamService:(id<StreamService>)service didReceiveStreamMetadadata:(StreamMetadata*)metadata;
- (void)streamService:(id<StreamService>)service streamMetadadataFetchFailed:(NSError*)error;

- (void)streamService:(id<StreamService>)service didUpdateStreamLocation:(Location *)location;

- (void)streamServiceLiveBroadcastsChanged:(id<StreamService>)service;

@end
