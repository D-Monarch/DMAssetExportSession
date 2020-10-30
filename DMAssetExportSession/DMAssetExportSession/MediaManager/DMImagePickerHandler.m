//
//  DMImagePickHandler.m
//  DMAssetExportSession
//
//  Created by yao wang on 2020/9/27.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DMImagePickerHandler.h"
#import "DMDefine.h"
#import "UIWindow+DMCurrentTopVC.h"
#import <Photos/Photos.h>


typedef NS_ENUM(NSInteger, DMMediaSource) {
    DMMediaSourceAlbumImage,
    DMMediaSourceCamera,
    DMMediaSourceAlbumMovie,
    DMMediaSourceTakeVideo
};


@interface DMImagePickerHandler()
<UINavigationControllerDelegate,
UIImagePickerControllerDelegate>

@property (nonatomic, copy) DMSelectMediaComplete complete;

@property (nonatomic,assign) DMMediaType mediaType;
@property (nonatomic,assign) DMMediaSource mediaSource;

@end

@implementation DMImagePickerHandler

- (void)showAlertWithMideaType:(DMMediaType)type completeHandler:(DMSelectMediaComplete)completeHandler {
    
    _complete = completeHandler;
    _mediaType = type;
    DMWeakSelf;
    UIAlertController *alertController = [[UIAlertController alloc] init];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"相册"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf isCanVisitPhotoLibrary:^(BOOL success) {
            if (success) {
                [weakSelf mediaWithSource:type == DMMediaTypeImage ? DMMediaSourceAlbumImage : DMMediaSourceAlbumMovie];
            }
        }];
    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"相机"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
        
        [weakSelf isCanVisitPhotoLibrary:^(BOOL success) {
            if (success) {
                [weakSelf mediaWithSource:type == DMMediaTypeImage ? DMMediaSourceCamera : DMMediaSourceTakeVideo];
            }
        }];
    }];
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        NSError *error = [NSError errorWithDomain:@"com.lionbridge.cn" code:100 userInfo:@{NSLocalizedDescriptionKey:@"取消操作"}];
        if (weakSelf.complete) {
            weakSelf.complete(nil, weakSelf.mediaType, error);
        }
    }];
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    
//    UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
//    popPresenter.sourceView = [[[UIApplication sharedApplication] keyWindow] lb_currentViewController].view;
//    popPresenter.sourceRect = [[UIApplication sharedApplication] keyWindow].bounds;

    [[[[UIApplication sharedApplication] keyWindow] dm_currentViewController] presentViewController:alertController animated:YES completion:nil];
}


/// 相册、相机调用设置
/// @param source 获取文件途径类型
- (void)mediaWithSource:(DMMediaSource)source {
    
    _mediaSource = source;
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    if (source == DMMediaSourceAlbumImage) {
        
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    } else if (source == DMMediaSourceCamera) {
        
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else if (source == DMMediaSourceAlbumMovie) {
        
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.mediaTypes = [NSArray arrayWithObjects:@"public.movie",  nil];
    } else {
        
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.mediaTypes = [NSArray arrayWithObjects:@"public.movie",  nil];
    }
    
    [[[[UIApplication sharedApplication] keyWindow] dm_currentViewController] presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    DMWeakSelf;
    NSString *mediaType=[info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:@"public.movie"]){
        //如果是视频
        NSURL *url;
        if (_mediaSource == DMMediaSourceAlbumMovie) {
            url = info[UIImagePickerControllerMediaURL] ?: info[UIImagePickerControllerReferenceURL];//获得视频的URL
        } else {
            url = info[UIImagePickerControllerMediaURL];
        }
        
        
        [picker dismissViewControllerAnimated:NO completion:^{
            if (weakSelf.complete) {
                weakSelf.complete(url, weakSelf.mediaType, nil);
            }
        }];
        
    } else {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        
        [picker dismissViewControllerAnimated:NO completion:^{
            if (weakSelf.complete) {
                weakSelf.complete(image, weakSelf.mediaType, nil);
            }
        }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    DMWeakSelf;
    NSError *error = [NSError errorWithDomain:@"com.lionbridge.cn" code:100 userInfo:@{NSLocalizedDescriptionKey:@"取消选择"}];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        if (weakSelf.complete) {
            weakSelf.complete(nil, weakSelf.mediaType, error);
        }
    }];
}

#pragma mark - 相册权限检测
- (void)isCanVisitPhotoLibrary:(void(^)(BOOL))result {
    
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        result(YES);
        return;
    }
    if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied) {
        result(NO);
        return ;
    }
    
    if (status == PHAuthorizationStatusNotDetermined) {
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            // 回调是在子线程的
            NSLog(@"%@",[NSThread currentThread]);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status != PHAuthorizationStatusAuthorized) {
                    NSLog(@"未开启相册权限,请到设置中开启");
                    result(NO);
                    return ;
                }
                result(YES);
            });
        }];
    }
}
@end
