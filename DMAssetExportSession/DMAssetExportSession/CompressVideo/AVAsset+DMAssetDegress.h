//
//  AVAsset+LBAssetDegress.h
//  ExportVideo
//
//  Created by yao wang on 2020/9/12.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAsset (DMAssetDegress)

/// 获取视频角度
- (int)degress;
/// 获取优化后的视频转向信息
- (AVMutableVideoComposition *)videoComposition;

@end

NS_ASSUME_NONNULL_END
