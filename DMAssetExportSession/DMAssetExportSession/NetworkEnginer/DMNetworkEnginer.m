//
//  DMNetworkEnginer.m
//  DMAssetExportSession
//
//  Created by yao wang on 2020/9/17.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import "DMNetworkEnginer.h"
#import "DMNetworkConfig.h"
#import <AFNetworking/AFNetworking.h>
#import "DMDefine.h"
#import "DMLoadingManager.h"


#ifdef DEBUG
#define DMNSLog(...) NSLog(__VA_ARGS__)
#define debugMethod() NSLog(@"%s", __func__)
#else
#define DMNSLog(...)
#define debugMethod()
#endif

@interface DMNetworkEnginer()
/**  */
@property (nonatomic, strong) NSMutableArray  *tasks;
@end

@implementation DMNetworkEnginer

//- (void)postReqeustHeaders:(NSDictionary *)headers
//                    params:(NSDictionary *)params
//                  complete:(void(^)(NSError *error, id  _Nullable responseObject))complete {
//
//    if (![DMNetworkConfig shareConfig].baseUrl && ![DMNetworkConfig shareConfig].path) {
//           DMNSLog(@"NetworkConfig error: Unconfigured base url or path");
//           return;
//    }
//    AFHTTPSessionManager *manager = [self managerOfHeaders:headers];
//
//    NSURLSessionDataTask *task = [manager POST:[self buildRequestUrl] parameters:params headers:headers progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        if (complete) {
//            complete(nil, responseObject);
//        }
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        if (complete) {
//            complete(error, task.response);
//        }
//    }];
//
//    [self.tasks addObject:task];
//}

- (void)postReqeustHeaders:(NSDictionary *)headers
                    params:(NSDictionary *)params
                      data:(NSData *)data
                       url:(NSURL *)url
                  fileType:(NSString *)fileType
                  fileName:(NSString *)fileName
                  progress:(void(^)(NSProgress * _Nonnull uploadProgress))progress
                  complete:(void(^)(NSError *error, id  _Nullable responseObject))complete {
    
    
    NSAssert(!(data == nil && url == nil), @"Can not find upload data");
    if (![DMNetworkConfig shareConfig].path) {
        DMNSLog(@"NetworkConfig error: Unconfigured base url or path");
        [[DMLoadingManager instance] showWithText:@"未配置上传url"];
        return;
    }

//    DMWeakSelf;
    AFHTTPSessionManager *manager = [self managerOfHeaders:headers];
//    [manager.requestSerializer setValue:@"form/data" forHTTPHeaderField:@"Content-Type"];

    for (NSString *key in headers.allKeys) {
        if (headers[key]) {
            [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
        }
    }

    NSURLSessionDataTask *task = [manager POST:[self buildRequestUrl]
                                    parameters:params
                     constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        if (data) {
            [formData appendPartWithFileData:data
                                        name:fileName
                                    fileName:@"compressImage"
                                    mimeType:fileType];
        } else {
            [formData appendPartWithFileURL:url
                                       name:fileName
                                   fileName:@"520P.mp4"
                                   mimeType:fileType
                                      error:nil];
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        dm_dispatch_main_async_safe(^{
            
            if (progress) {
                progress(uploadProgress);
            }
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        dm_dispatch_main_async_safe(^{
            if (complete) {
                complete(nil, responseObject);
            }
        })
       
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dm_dispatch_main_async_safe(^{

            if (complete) {
                complete(error, nil);
            }
        });
    }];
    
    [self.tasks addObject:task];
}

- (AFHTTPSessionManager *)managerOfHeaders:(NSDictionary *)headers {
    
    AFHTTPSessionManager *manager = [DMNetworkConfig shareConfig].manager;
    for (NSString *key in headers.allKeys) {
        [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
    }
    manager.requestSerializer.timeoutInterval = [DMNetworkConfig shareConfig].timeoutInterval;
    return manager;
}

- (NSString *)buildRequestUrl {
    
    if (![DMNetworkConfig shareConfig].path) {
        return nil;
    }
//    NSParameterAssert([DMNetworkConfig shareConfig].baseUrl != nil || [DMNetworkConfig shareConfig].baseUrl != nil);

    NSURL *temp = [NSURL URLWithString:[DMNetworkConfig shareConfig].path];
    
    // If detailUrl is valid URL
    if (temp && temp.host && temp.scheme) {
        return [DMNetworkConfig shareConfig].path;
    }
    
    NSURL *url = [NSURL URLWithString:[DMNetworkConfig shareConfig].baseUrl];
    
    return [url URLByAppendingPathComponent:[DMNetworkConfig shareConfig].path].absoluteString;
}


- (void)cancelRequestWithUrl:(NSString *)url {
    for (NSURLSessionDataTask *task in self.tasks) {
        if (task.currentRequest && [url isEqualToString:task.currentRequest.URL.absoluteString]) {
            [task cancel];
            break;
        }
    }
}

- (void)cancelAllRequest {
    
    for (NSURLSessionDataTask *task in self.tasks) {
        if (task.currentRequest) {
            [task cancel];
        }
    }
}


- (NSMutableArray *)tasks {
    if (!_tasks) {
        _tasks = [NSMutableArray array];
    }
    return _tasks;
}


@end
