//
//  UIImage+LBCompress.h
//  ExportVideo
//
//  Created by yao wang on 2020/9/16.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (DMCompression)

/// 图片压缩
/// @param completionHandler complete
- (void)dm_compressCompletionHandler:(void(^)(UIImage *image, NSError *error))completionHandler;


/// 图片压缩
/// @param maxBytes 指定压缩最大字节数
/// @param completionHandler complete
- (void)dm_compressWithMaxBytes:(NSInteger)maxBytes completionHandler:(void(^)(UIImage *image, NSError *error))completionHandler;

@end

NS_ASSUME_NONNULL_END
