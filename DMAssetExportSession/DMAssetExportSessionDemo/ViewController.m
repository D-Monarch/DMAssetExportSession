//
//  ViewController.m
//  DMAssetExportSessionDemo
//
//  Created by yao wang on 2020/10/30.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import "ViewController.h"
#import <DMAssetExportSession/DMAssetExportSession.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(100, 80, 100, 50);
    [btn setTitle:@"视频压缩测试" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(compress) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];

    // Do any additional setup after loading the view.
}

- (void)compress {
    [[DMMediaManager shareManaegr] handleMediaWithParams:nil headers:nil complete:^(NSString * _Nonnull result) {
        
    }];
}
@end
