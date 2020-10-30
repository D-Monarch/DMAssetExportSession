//
//  DMImagePickHandler.h
//  DMAssetExportSession
//
//  Created by yao wang on 2020/9/27.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DMDefine.h"

typedef void(^DMSelectMediaComplete)(id _Nullable result, DMMediaType type, NSError *error);

NS_ASSUME_NONNULL_BEGIN

@interface DMImagePickerHandler : NSObject

- (void)showAlertWithMideaType:(DMMediaType)type completeHandler:(DMSelectMediaComplete)completeHandler;

@end

NS_ASSUME_NONNULL_END
