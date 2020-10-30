//
//  LBSLoadingManager.h
//  LionBridge
//
//  Created by yao wang on 2019/3/2.
//  Copyright © 2019年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MBProgressHUD/MBProgressHUD.h>

@class DMLoadingManager;

NS_ASSUME_NONNULL_BEGIN

@interface DMLoadingManager : NSObject

@property (nonatomic,assign) float progress;

@property (nonatomic,assign) MBProgressHUDMode progressHubMode;


+ (DMLoadingManager *)instance;

- (void)show;

- (void)showWithText:(NSString *)text;


- (void)showWithText:(NSString *)text during:(NSTimeInterval)second;

- (void)showLoadingText:(NSString *)text;

- (void)showLoadingProgressText:(NSString *)text;

- (void)changeLoadingText:(NSString *)text;

- (void)hide;
@end

NS_ASSUME_NONNULL_END
