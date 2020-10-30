//
//  DMAssetExportSession.h
//  ExportVideo
//
//  Created by yao wang on 2020/9/2.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DMDefine.h"

@protocol DMAssetExportSessionDelegate;

typedef void(^DMCompletionHandler)(AVAssetExportSessionStatus status, NSError * _Nullable error);

typedef void(^DMProgress)(CGFloat progress);

NS_ASSUME_NONNULL_BEGIN


@interface DMAssetExportSessionManager : NSObject


@property (nonatomic, weak) id<DMAssetExportSessionDelegate> delegate;

@property (nullable ,nonatomic, copy) NSURL *outputURL;

/**
 *AVFileType 输出视频格式     Default is AVFileTypeMPEG4
 *AVFileTypeMPEG4           Indicates the MPEG-4 format.
 *AVFileTypeWAVE            Indicates the Apple WAVE Movie format
 *AVFileTypeMPEGLayer3      Indicates the MPEG layer 3 format.
 *AVFileTypeQuickTimeMovie  Indicates the Apple QuickTime Movie format
 *...
*/
@property (nonatomic, copy) NSString *outputFileType;

/// 设置metadata
@property (nonatomic, copy) NSArray *metadata;

/// 压缩进度
@property (readonly, nonatomic, assign) CGFloat progress;
/// 导出视频大小
@property (readonly, nonatomic, assign) float estimatedExportSize;
/// 状态
@property (nonatomic, assign, readonly) AVAssetExportSessionStatus status;
/// 错误信息
@property (nonatomic, strong, readonly) NSError *error;


/// 初始化 designated Initializers
/// @param url    视频地址
/// @param preset 压缩预设分辨率
- (instancetype)initWithURL:(nonnull NSURL *)url preset:(DMExportVideoPreset)preset;

/// 初始化 secondary Initializers
/// @param asset AVAsset 对象
/// @param preset 压缩预设分辨率
- (instancetype)initWithAsset:(nonnull AVAsset *)asset preset:(DMExportVideoPreset)preset;

/// 视频压缩
/// @param completeHandler 结束回调
- (void)exportAsynWithProgress:(DMProgress)progress completeHandler:(DMCompletionHandler)completeHandler;

/// 取消压缩
- (void)cancel;

@end


@protocol DMAssetExportSessionDelegate <NSObject>

@optional

- (void)assetSession:(DMAssetExportSessionManager *)session progress:(CGFloat)progress;

- (BOOL)assetSession:(DMAssetExportSessionManager *)session
         renderFrame:(CVPixelBufferRef)renderFrame
    presentationTime:(CMTime)presentationTime
            toBuffer:(CVPixelBufferRef)toBuffer;

@end
NS_ASSUME_NONNULL_END
