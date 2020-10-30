//
//  DMNetworkConfig.m
//  DMAssetExportSession
//
//  Created by yao wang on 2020/9/18.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import "DMNetworkConfig.h"
#import <AFNetworking/AFNetworking.h>

@implementation DMNetworkConfig

+ (instancetype)shareConfig {
    
    static dispatch_once_t onceToken;
    static DMNetworkConfig *config;
    dispatch_once(&onceToken, ^{
        
        config = [[DMNetworkConfig alloc] init];
    });
    return config;
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        _manager = [AFHTTPSessionManager manager];
        _baseUrl = @"";
        _timeoutInterval = 60;

        _manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        _manager.securityPolicy = [AFSecurityPolicy defaultPolicy];
        
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/plain", @"text/javascript", @"text/json",@"text/html",nil];
    }
    return self;
}

@end
