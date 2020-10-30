//
//  UIWindow+DMCurrentTopVC.h
//  LionBridge
//
//  Created by yao wang on 2019/3/2.
//  Copyright © 2019年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (DMCurrentTopVC)
/*!
 @method topMostController
 
 @return Returns the current Top Most ViewController in hierarchy.
 */
- (UIViewController *)dm_topMostController;

/*!
 @method currentViewController
 
 @return Returns the topViewController in stack of topMostController.
 */
- (UIViewController *)dm_currentViewController;

@end

NS_ASSUME_NONNULL_END
