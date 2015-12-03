//
//  UUID.m
//  blt
//
//  Copyright (c) 2012 Mobileman. All rights reserved.
//

#import "UUID.h"

@interface UUID () 

@property (nonatomic, retain, readwrite) NSString * value;

@end

@implementation UUID

@synthesize value = _value;

- (id)initWithString:(NSString*)val {
    if (self = [super init]) {
        self.value = val;
    }
    
    return self;
}

+ (NSString*)nullUUIDString {
    static dispatch_once_t once;
    static NSString * nullUUIDString;
    dispatch_once(&once, ^{
        nullUUIDString = @"00000000-0000-0000-0000-000000000000";
    });
    return nullUUIDString;
}

+ (UUID*)fromString:(NSString*)value {
    UUID *uuid = [[UUID alloc] initWithString:value];
    return uuid;
}

+ (UUID*)newUUID {
    CFUUIDRef _uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString * stringVal = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, _uuid);
    UUID *uuid = [[UUID alloc] initWithString:stringVal];
    CFRelease(_uuid);
    return uuid;
}

+ (NSString*)newUUIDString {
    CFUUIDRef _uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString * stringVal = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, _uuid);
    CFRelease(_uuid);
    return [stringVal lowercaseString];
}

@end
