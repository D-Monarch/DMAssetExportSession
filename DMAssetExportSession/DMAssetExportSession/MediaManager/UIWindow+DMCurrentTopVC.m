//
//  UIWindow+DMCurrentTopVC.m
//  LionBridge
//
//  Created by yao wang on 2019/3/2.
//  Copyright © 2019年 apple. All rights reserved.
//

#import "UIWindow+DMCurrentTopVC.h"

@implementation UIWindow (DMCurrentTopVC)

- (UIViewController *)dm_topMostController {
    UIViewController *topController = [self rootViewController];
    
    //  Getting topMost ViewController
    while ([topController presentedViewController]) {
        topController = [topController presentedViewController];
    }
    
    //  Returning topMost ViewController
    return topController;
}

- (UIViewController *)dm_currentViewController; {
    UIViewController *currentViewController = [self dm_topMostController];
    
    if ([currentViewController isKindOfClass:[UITabBarController class]]) {
        currentViewController = [(UITabBarController *) currentViewController selectedViewController];
    }
    
    while ([currentViewController isKindOfClass:[UINavigationController class]]
           && [(UINavigationController *) currentViewController topViewController]) {
        currentViewController = [(UINavigationController *) currentViewController topViewController];
    }
    
    return currentViewController;
}

@end
