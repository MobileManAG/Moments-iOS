//
//  UUID.h
//  blt
//
//  Copyright (c) 2012 Mobileman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UUID : NSObject {
    
    
}

@property (nonatomic, retain, readonly) NSString * value;

+ (UUID*)fromString:(NSString*)value;
+ (UUID*)newUUID;
+ (NSString*)newUUIDString;
+ (NSString*)nullUUIDString;

@end
