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
//  StreamServiceImpl.m
//  moments
//
//  Created by MobileMan GmbH on 28.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

@import CoreLocation;

#import "StreamServiceImpl.h"
#import "WSBindingImpl.h"
#import "StreamMetadata.h"
#import "Stream.h"
#import "Location.h"
#import "User.h"
#import "Settings.h"
#import "UserSession.h"
#import "Comment.h"
#import "Slice.h"

@implementation StreamServiceImpl

@synthesize delegate;

-(id)initWithDelegate:(id<StreamServiceDelegate>)_delegate {
    if (self = [self init]) {
        self.delegate = _delegate;
        self.wsBinding = [WSBindingImpl instance];
        _liveBroadcastsQueue = dispatch_queue_create("com.mobileman.moments.live.streams.queue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (void)dealloc
{

}

- (void) reverseGeocodeStream:(Stream*)stream success:(void (^)(Location * location))success {
    if (stream.location == nil || ![stream.location needsReverseGeocoding]) {
        return;
    }
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:stream.location.latitude longitude:stream.location.longitude];
    if (!location) {
        return;
    }
    
    self.geocoder = [[CLGeocoder alloc] init];
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            LogError(@"Error geocoding stream: %@", error);
            return;
        }
        
        if (placemarks.count == 0) {
            LogError(@"No placemarks for location: lat=%f, long=%f", stream.location.latitude, stream.location.longitude);
            return;
        }
        CLPlacemark *placemark = [placemarks firstObject];
        stream.location.city = placemark.locality;
        stream.location.state = placemark.administrativeArea;
        stream.location.country = placemark.country;
        
        if (stream.location.city == nil) {
            stream.location.city = @"";
        }
        
        if (stream.location.state == nil) {
            stream.location.state = @"";
        }
        
        if (stream.location.country == nil) {
            stream.location.country = @"";
        }
        
        success(stream.location);
        
    }];
}

- (void)liveBroadcasts:(void (^)(id<Slice> streams))success failure:(void (^)(NSError *error))failure {
    
    [self.wsBinding liveBroadcasts:^(id<Slice> streams) {
        success(streams);
        [self createLiveBroadcastsChnagedTimer];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)streamService:(id<StreamService>)service liveBroadcastsChanged:(id<Slice>)streams {
    
}

- (void)createStreamMetadataFetchTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:STREAM_METADATA_FETCH_TIME target:self selector:@selector(onMetadataTimer:) userInfo:nil repeats:YES];
}

-(void)onMetadataTimer:(NSTimer *)timer {
    if (!self.stream || self.isMetadataFetchInProgress) {
        return;
    }
    
    self.isMetadataFetchInProgress = true;
    [self.wsBinding fetchStreamMetadata:self.stream timestamp:self.lastStreamEventTimestamp success:^(StreamMetadata *metadata) {
        if (!self.stream.location) {
            self.stream.location = metadata.location;
        }
        
        if (!self.geocoder && self.stream.location && !self.stream.location.city) {
            [self reverseGeocodeStream:self.stream success:^(Location * location){
                if ([self.delegate respondsToSelector:@selector(streamService:didUpdateStreamLocation:)]) {
                    [self.delegate streamService:self didUpdateStreamLocation:location];
                }
            }];
        }
        
        if ([self.delegate respondsToSelector:@selector(streamService:didReceiveStreamMetadadata:)]) {
            
            if (metadata.events.count) {
                Comment * event = metadata.events.lastObject;
                self.lastStreamEventTimestamp = @(event.timestamp);
            }
            
            [self.delegate streamService:self didReceiveStreamMetadadata:metadata];
        }
        
        self.isMetadataFetchInProgress = false;
        
    } failure:^(NSError *error) {
        self.isMetadataFetchInProgress = false;
        if ([self.delegate respondsToSelector:@selector(streamService:streamMetadadataFetchFailed:)]) {
            [self.delegate streamService:self streamMetadadataFetchFailed:error];
        }
        
    }];
}

- (void)createLiveBroadcastsChnagedTimer {
    if (self.liveBroadcastsTimer == nil) {
        self.liveBroadcastsTimer = [NSTimer scheduledTimerWithTimeInterval:LIVE_STREAMS_CHANGE_INTERVAL target:self selector:@selector(onLiveBroadcastsChangedTimer:) userInfo:nil repeats:YES];
    }
}

-(void)onLiveBroadcastsChangedTimer:(NSTimer *)timer {
    dispatch_sync( self.liveBroadcastsQueue, ^{
        if ([self.delegate respondsToSelector:@selector(streamServiceLiveBroadcastsChanged:)]) {
            [self.delegate streamServiceLiveBroadcastsChanged:self];
        }
    });
}

- (void)joinBroadcast:(Stream *)stream success:(void (^)(StreamMetadata * metadata))success failure:(void (^)(NSError *error))failure {
    UserSession * session = [Settings currentSession];
    if (session == nil) {
        return;
    }
    
    if ([stream.user isEqual:session.user]) {
        [self createStreamMetadataFetchTimer];
        self.stream = stream;
        success(nil);
        return;
    }
    
    [self.wsBinding joinBroadcast:stream success:^(StreamMetadata *metadata) {
        self.stream = stream;
        [self createStreamMetadataFetchTimer];
        success(metadata);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)leaveBroadcast:(Stream *)stream success:(void (^)(StreamMetadata * metadata))success failure:(void (^)(NSError *error))failure {
    UserSession * session = [Settings currentSession];
    if (self.stream == nil || session == nil) {
        return;
    }
    
    if ([self.stream.user isEqual:session.user]) {
        self.stream = nil;
        [self.timer invalidate];
        self.timer = nil;
        success(nil);
        return;
    }
    
    self.stream = nil;
    [self.timer invalidate];
    self.timer = nil;
    
    [self.wsBinding leaveBroadcast:stream success:^(StreamMetadata *metadata) {
         success(metadata);
     } failure:^(NSError *error) {
         failure(error);
     }];
}

- (void)postComment:(Stream *)stream text:(NSString *)text success:(void (^)(StreamMetadata * metadata))success failure:(void (^)(NSError *error))failure {
    if (self.stream == nil) {
        return;
    }
    
    [self.wsBinding postComment:stream text:text success:^(void) {
        success(nil);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)deleteStream:(Stream *)stream text:(NSString *)text success:(void (^)(Stream * stream))success failure:(void (^)(NSError *error))failure {
    if (stream == nil) {
        return;
    }
    
    [self.wsBinding deleteStream:stream success:^(Stream * deletedStream) {
        success(deletedStream);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

@end
