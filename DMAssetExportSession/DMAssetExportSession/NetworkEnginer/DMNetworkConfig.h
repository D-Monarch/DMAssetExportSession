//
//  LBNetworkConfig.h
//  LBAssetExportSession
//
//  Created by yao wang on 2020/9/18.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AFHTTPSessionManager;

NS_ASSUME_NONNULL_BEGIN

@interface DMNetworkConfig : NSObject

@property (nonatomic, strong) AFHTTPSessionManager *manager;

/// 域名配置
@property (nonatomic, copy) NSString *baseUrl;

/// 视频上传path(可配置为全路径)
@property (nonatomic, copy) NSString *path;

/** 超时时间 */
@property (nonatomic,assign) NSInteger timeoutInterval;


+ (instancetype)shareConfig;

@end

NS_ASSUME_NONNULL_END
