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
//  MomAWSS3.m
//  moments
//
//  Created by MobileMan GmbH on 20.4.2015.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "MomAWSS3.h"
#import <AWSS3/AWSS3.h>

#define MAIN_S3 @"MainS3"
#define MAIN_S3_MANAGER @"MainManager"

@implementation MomAWSS3

+ (AWSServiceConfiguration *)awsServiceConfiguration:(NSString *)accessKey secretKey:(NSString *)secretKey {
    id<AWSCredentialsProvider> credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:accessKey secretKey:secretKey];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1
                                                                         credentialsProvider:credentialsProvider];
    
    configuration.maxRetryCount = 1;
    
    return configuration;
}

+ (AWSS3 *)S3:(NSString *)accessKey secretKey:(NSString *)secretKey {
    [AWSS3 removeS3ForKey:MAIN_S3];
    [AWSS3 registerS3WithConfiguration:[self awsServiceConfiguration:accessKey secretKey:secretKey] forKey:MAIN_S3];
    AWSS3 * s3 = [AWSS3 S3ForKey:MAIN_S3];
    return s3;
}

+ (AWSS3TransferManager *)S3TransferManager:(NSString *)accessKey secretKey:(NSString *)secretKey {
    [AWSS3TransferManager removeS3TransferManagerForKey:MAIN_S3_MANAGER];
    [AWSS3TransferManager registerS3TransferManagerWithConfiguration:[self awsServiceConfiguration:accessKey secretKey:secretKey] forKey:MAIN_S3_MANAGER];
    AWSS3TransferManager * manager = [AWSS3TransferManager S3TransferManagerForKey:MAIN_S3_MANAGER];
    return manager;
}

@end
