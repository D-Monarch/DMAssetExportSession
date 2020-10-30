//
//  DMNetworkEnginer.h
//  DMAssetExportSession
//
//  Created by yao wang on 2020/9/17.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DMNetworkEnginer : NSObject

///// POST 请求
///// @param headers headers
///// @param params params
///// @param complete complete
//- (void)postReqeustHeaders:(NSDictionary *)headers
//                    params:(NSDictionary *)params
//                  complete:(void(^)(NSError *error, id  _Nullable responseObject))complete;

/// 上传文件
/// @param headers headers
/// @param params params
/// @param data 文件
/// @param url 文件路径
/// @param fileType 文件类型
/// @param fileName 文件名称（与服务端对照）
/// @param complete complete
- (void)postReqeustHeaders:(NSDictionary *)headers
                    params:(NSDictionary *)params
                      data:(nullable NSData *)data
                       url:(nullable NSURL *)url
                  fileType:(NSString *)fileType
                  fileName:(NSString *)fileName
                  progress:(void(^)(NSProgress * _Nonnull uploadProgress))progress
                  complete:(void(^)(NSError *error, id  _Nullable responseObject))complete;

- (void)cancelRequestWithUrl:(NSString *)url;

- (void)cancelAllRequest;

@end

NS_ASSUME_NONNULL_END
