//
//  DMEnumDefine.h
//  ExportVideo
//
//  Created by yao wang on 2020/9/12.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#ifndef DMEnumDefine_h
#define DMEnumDefine_h

#define DMWeakSelf     __weak __typeof(self) weakSelf = self

//#ifdef DEBUG
#define DMNSLog(...) NSLog(__VA_ARGS__)
#define debugMethod() NSLog(@"%s", __func__)
//#else
//#define DMNSLog(...)
//#define debugMethod()
//#endif

#define dm_dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
    block();\
} else {\
    dispatch_async(dispatch_get_main_queue(), block);\
}

#define dm_dispatch_after_main_async_safe(block)\
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.001 * NSEC_PER_SEC), dispatch_get_main_queue(), block)


#define DMWeakSelf     __weak __typeof(self) weakSelf = self
#define DMStrongSelf   __strong typeof(weakSelf) strongSelf = weakSelf

#define kScreenW    [UIScreen mainScreen].bounds.size.width
#define kScreenH    [UIScreen mainScreen].bounds.size.height

typedef NS_ENUM(NSInteger, DMMediaType) {
    DMMediaTypeImage,
    DMMediaTypeVideo
};

typedef NS_ENUM(NSUInteger, DMExportVideoPreset) {
    DMExportVideoPreset240P,
    DMExportVideoPreset360P,
    DMExportVideoPreset480P,
    DMExportVideoPreset540P,
    DMExportVideoPreset720P,
    DMExportVideoPreset1080P,
    DMExportVideoPreset2K, // 1440P
    DMExportVideoPreset4K, // 2160P
};



#endif /* DMEnumDefine_h */
