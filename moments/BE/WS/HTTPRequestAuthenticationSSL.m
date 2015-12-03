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
//  HTTPRequestAuthenticationSSL.m
//  moments
//
//  Created by MobileMan GmbH on 21.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "HTTPRequestAuthenticationSSL.h"

static CFArrayRef _knownCertificates = nil;

@implementation HTTPRequestAuthenticationSSL

+ (void)initialize {
    __block NSMutableArray * allCerts = [NSMutableArray arrayWithCapacity:4];
    
    for (NSData * data in [self validationCertificates]) {
        SecCertificateRef rootcert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(data));
        [allCerts addObject:(__bridge id)(rootcert)];
        CFRelease(rootcert);
    }
    
    _knownCertificates = CFBridgingRetain(allCerts);
}

+ (NSArray *)validationCertificates {
    NSMutableArray * certNames = [NSMutableArray arrayWithObjects:@"prod-server", nil];
#ifdef DEBUG
    [certNames addObject:@"dev-server"];
#endif
    
    NSMutableArray * validationCertificates = [NSMutableArray arrayWithCapacity:certNames.count];

    for (NSString * name in certNames) {
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"cer"];
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data == nil) {
            path = [[NSBundle mainBundle] pathForResource:name ofType:@"der"];
            data = [NSData dataWithContentsOfFile:path];
        }
        if (data != nil) {
            [validationCertificates addObject:data];
        }
    }
    
    return validationCertificates;
}

- (NSURLSessionAuthChallengeDisposition)authenticate:(NSURLSession *)session challenge:(NSURLAuthenticationChallenge *)challenge credential:(NSURLCredential *__autoreleasing *)credential {
    
    if (![challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        return NSURLSessionAuthChallengePerformDefaultHandling;
    }
    
    SecTrustRef trustRef = NULL;
    long trustCertificateCount = SecTrustGetCertificateCount(challenge.protectionSpace.serverTrust);
    
    NSMutableArray* trustCertificates = [[NSMutableArray alloc] initWithCapacity:trustCertificateCount];
    for (int i = 0; i < trustCertificateCount; i++) {
        SecCertificateRef trustCertificate =  SecTrustGetCertificateAtIndex(challenge.protectionSpace.serverTrust, i);
        [trustCertificates addObject:(__bridge id) trustCertificate];
    }
    
    SecPolicyRef policyRef = SecPolicyCreateSSL(YES, (__bridge CFStringRef) challenge.protectionSpace.host);
    SecTrustCreateWithCertificates((__bridge CFArrayRef) trustCertificates, policyRef, &trustRef);
    
    // load known certificates from keychain and set as anchor certificates
    NSMutableDictionary* secItemCopyCertificatesParams = [[NSMutableDictionary alloc] init];
    [secItemCopyCertificatesParams setObject:(__bridge id)(kSecClassCertificate) forKey:(__bridge id)(kSecClass)];
    [secItemCopyCertificatesParams setObject:@"Server_Cert_Label" forKey:(__bridge id)kSecAttrLabel];
    [secItemCopyCertificatesParams setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnRef];
    [secItemCopyCertificatesParams setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];
    
    CFArrayRef tmpCertificates = nil;
    SecItemCopyMatching((__bridge CFDictionaryRef) secItemCopyCertificatesParams, (CFTypeRef*) &tmpCertificates);
    
    CFMutableArrayRef certificates = CFArrayCreateMutable(NULL, 10, NULL);
    
    if (_knownCertificates) {
        CFRange range = {0, CFArrayGetCount(_knownCertificates)};
        CFArrayAppendArray(certificates, _knownCertificates, range);
    }
    
    if (tmpCertificates) {
        CFRange range = {0, CFArrayGetCount(tmpCertificates)};
        CFArrayAppendArray(certificates, tmpCertificates, range);
        CFRelease(tmpCertificates);
    }
    
    if (certificates == nil) {
        // set empty array as own anchor certificate so system anchos certificates are used too!
        SecTrustSetAnchorCertificates(trustRef, (__bridge CFArrayRef) [NSArray array]);
        SecTrustSetAnchorCertificatesOnly(trustRef, NO);
    } else {
        SecTrustSetAnchorCertificates(trustRef, certificates);
        SecTrustSetAnchorCertificatesOnly(trustRef, YES);
    }
    
    CFRelease(certificates);
    CFRelease(policyRef);
    
    SecTrustResultType result;
    OSStatus trustEvalStatus = SecTrustEvaluate(trustRef, &result);
    NSLog(@"SecTrustEvaluate result: %d", (int)result);
    BOOL trusted = (trustEvalStatus == noErr) && (
                                                  (result == kSecTrustResultProceed) ||
                                                  (result == kSecTrustResultUnspecified)
                                                  );
    CFRelease(trustRef);
    //trusted = YES;
    if (trusted) {
        NSLog(@"Trust evaluation suceeded for service root certificate");
        [[challenge sender] useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
         return NSURLSessionAuthChallengeUseCredential;
    } else {
        NSLog(@"Trust evaluation failed for service root certificate");
        // TODO notify FE ?
#ifdef DEBUG
        // also ban in DEV mode
        [[challenge sender] useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        return NSURLSessionAuthChallengeUseCredential;
#endif
    }
    
    return NSURLSessionAuthChallengePerformDefaultHandling;
}


@end
