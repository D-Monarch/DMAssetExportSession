//
//  DMMediaManager.h
//  DMAssetExportSession
//
//  Created by yao wang on 2020/9/18.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DMMediaManager : NSObject


/// 压缩视频输出地址
@property (nullable ,nonatomic, copy) NSURL *outputURL;

/**
 *AVFileType 输出视频格式     默认 AVFileTypeMPEG4
 *AVFileTypeMPEG4           Indicates the MPEG-4 format.
 *AVFileTypeWAVE            Indicates the Apple WAVE Movie format
 *AVFileTypeMPEGLayer3      Indicates the MPEG layer 3 format.
 *AVFileTypeQuickTimeMovie  Indicates the Apple QuickTime Movie format
 *...
 */
@property (nonatomic, copy) NSString *outputFileType;

/// 视频压缩进度(0-1)
@property (readonly, nonatomic, assign) CGFloat progress;

/// 导出视频大小(M)
@property (readonly, nonatomic, assign) CGFloat estimatedExportSize;

/// 是否显示loading
@property (nonatomic,assign) BOOL showLoading;


+ (instancetype)shareManaegr;


/// 处理媒体文件方法
/// @param params 上传参数
/// @param headers 上传头
/// @param completionHandler return string
- (void)handleMediaWithParams:(nullable NSDictionary *)params
                      headers:(nullable NSDictionary *)headers
                     complete:(void (^)(NSString *result))completionHandler;

/// 上传图片
/// @param image image
/// @param params 请求参数
/// @param headers 请求头
/// @param completionHandler 回调处理
- (void)uploadImage:(UIImage *)image
             params:(nullable NSDictionary *)params
            headers:(nullable NSDictionary *)headers
           progress:(void(^)(NSProgress * _Nonnull uploadProgress))progress

           complete:(void (^)(id _Nullable responseObject, NSError * _Nonnull error))completionHandler;

/// 上传视频
/// @param url 视频url（支持本地路径和相册路径）
/// @param params 请求参数
/// @param headers 请求头
/// @param completionHandler 回调处理
- (void)uploadVideoURL:(NSURL *)url
                params:(nullable NSDictionary *)params
               headers:(nullable NSDictionary *)headers
              progress:(void(^)(NSProgress * _Nonnull uploadProgress))progress
              complete:(void (^)(id _Nullable responseObject, NSError * _Nonnull error))completionHandler;

/// 图片压缩
/// @param image image
/// @param completionHandler blcok
- (void)compressImage:(UIImage *)image complete:(void (^)(UIImage *image, NSError * _Nonnull error))completionHandler;


/// 视频压缩
/// @param url 视频URL
/// @param progressBlock 压缩进度
/// @param completionHandler block
- (void)compressVideoURL:(NSURL *)url
                progress:(void(^)(CGFloat progress))progressBlock
                complete:(void (^)(AVAssetExportSessionStatus status, NSURL *outputURL,  NSError * _Nonnull error))completionHandler;


/// 视频压缩
/// @param asset AVAsset
/// @param progressBlock 压缩进度
/// @param completionHandler block
- (void)compressVideoAsset:(AVAsset *)asset
                  progress:(void(^)(CGFloat progress))progressBlock
                  complete:(void (^)(AVAssetExportSessionStatus status, NSURL *url, NSError * _Nonnull error))completionHandler;


/// 取消上传操作
- (void)cancelAllReqeust;

@end

NS_ASSUME_NONNULL_END
