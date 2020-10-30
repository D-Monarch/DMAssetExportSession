//
//  DMSLoadingManager.m
//  LionBridge
//
//  Created by yao wang on 2019/3/2.
//  Copyright © 2019年 apple. All rights reserved.
//

#import "DMLoadingManager.h"
#import "UIWindow+DMCurrentTopVC.h"
#import "DMDefine.h"

@interface DMLoadingManager()


@property (nonatomic,strong) MBProgressHUD *hud;
@property (nonatomic,assign) BOOL showing;
/** <#注释#> */
@property (nonatomic,assign) BOOL canceled;

@end

@implementation DMLoadingManager

+ (DMLoadingManager *)instance {
    
    static DMLoadingManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[DMLoadingManager alloc] init];
    });
    
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _progressHubMode = MBProgressHUDModeAnnularDeterminate;
        _progress = 0;
    }
    return self;
}


- (void)show {
    
    DMWeakSelf;
    dm_dispatch_after_main_async_safe(^{
        if (weakSelf.hud) {
            [weakSelf.hud hideAnimated:NO];
            weakSelf.hud = nil;
        }
        UIView *viewCur = [UIApplication sharedApplication].keyWindow.rootViewController.view;
        weakSelf.hud = [MBProgressHUD showHUDAddedTo:viewCur animated:YES];
        weakSelf.hud.contentColor = [UIColor whiteColor];
        weakSelf.hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        weakSelf.hud.contentColor = [UIColor whiteColor];
        weakSelf.hud.bezelView.color = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        weakSelf.hud.mode = MBProgressHUDModeIndeterminate;
        weakSelf.hud.label.adjustsFontSizeToFitWidth = YES;
        weakSelf.hud.removeFromSuperViewOnHide = YES;
        [weakSelf.hud showAnimated:YES];
    });
}

- (void)showWithText:(NSString *)text {
    
    [self showWithText:text during:1.5];
}

- (void)showWithText:(NSString *)text during:(NSTimeInterval)second {
    
    if (text.length == 0) {
        return;
    }
    DMWeakSelf;
    dm_dispatch_after_main_async_safe(^{
        
        if (weakSelf.hud) {
            [weakSelf.hud hideAnimated:NO];
            weakSelf.hud = nil;
        }
        
        UIView *viewCur = [UIApplication sharedApplication].keyWindow.rootViewController.view;
        weakSelf.hud = [MBProgressHUD showHUDAddedTo:viewCur animated:YES];
        weakSelf.hud.contentColor = [UIColor whiteColor];
        weakSelf.hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        weakSelf.hud.contentColor = [UIColor whiteColor];
        weakSelf.hud.bezelView.color = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        weakSelf.hud.mode = MBProgressHUDModeText;
        weakSelf.hud.label.text = text;
        weakSelf.hud.label.adjustsFontSizeToFitWidth = YES;
        weakSelf.hud.removeFromSuperViewOnHide = YES;
        
        weakSelf.hud.completionBlock = ^{
            weakSelf.showing = NO;
        };
        [weakSelf.hud showAnimated:YES];
        
        if (second) {
            [weakSelf.hud hideAnimated:YES afterDelay:second];
        }
    });
}


- (void)showLoadingText:(NSString *)text {
    
    if (text.length == 0) {
        return;
    }
    DMWeakSelf;
    dm_dispatch_after_main_async_safe(^{
        
        if (weakSelf.hud) {
            [weakSelf.hud hideAnimated:NO];
            weakSelf.hud = nil;
        }
        
        UIView *viewCur = [UIApplication sharedApplication].keyWindow.rootViewController.view;
        weakSelf.hud = [MBProgressHUD showHUDAddedTo:viewCur animated:YES];
        weakSelf.hud.contentColor = [UIColor whiteColor];
        weakSelf.hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        weakSelf.hud.contentColor = [UIColor whiteColor];
        weakSelf.hud.bezelView.color = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        weakSelf.hud.mode = MBProgressHUDModeText;
        weakSelf.hud.label.text = text;
        weakSelf.hud.label.adjustsFontSizeToFitWidth = YES;
        weakSelf.hud.removeFromSuperViewOnHide = YES;
        
        [weakSelf.hud showAnimated:YES];
    });
}


- (void)showLoadingProgressText:(NSString *)text {
    DMWeakSelf;
    dm_dispatch_after_main_async_safe(^{
        if (weakSelf.hud) {
            [weakSelf.hud hideAnimated:NO];
            weakSelf.hud = nil;
        }
        UIView *viewCur = [UIApplication sharedApplication].keyWindow.rootViewController.view;
        weakSelf.hud = [MBProgressHUD showHUDAddedTo:viewCur animated:YES];
        weakSelf.hud.label.text = text;
        weakSelf.hud.mode = self.progressHubMode;
        [weakSelf.hud showAnimated:YES];
    });
}

- (void)changeLoadingText:(NSString *)text {
    self.hud.label.text = text;
}

- (void)hide {
    DMWeakSelf;
    dm_dispatch_main_async_safe(^{
        if (weakSelf.hud) {
            [weakSelf.hud hideAnimated:NO];
        }
    });
}


- (void)setProgress:(float)progress {
    DMWeakSelf;
    dm_dispatch_main_async_safe(^{
        if (weakSelf.hud) {
            weakSelf.hud.progress = progress;
        }
    });
}
@end
