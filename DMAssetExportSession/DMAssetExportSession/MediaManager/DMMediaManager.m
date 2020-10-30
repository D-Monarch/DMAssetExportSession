//
//  LBMediaManager.m
//  DMAssetExportSession
//
//  Created by yao wang on 2020/9/18.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import "DMMediaManager.h"
#import "DMNetworkEnginer.h"
#import "DMNetworkConfig.h"
#import "DMLoadingManager.h"
#import "DMImagePickerHandler.h"
#import "UIImage+DMCompression.h"
#import "DMAssetExportSessionManager.h"
#import <Photos/Photos.h>


@interface DMMediaManager()

@property (nonatomic, strong) DMNetworkEnginer *enginer;
/** <#注释#> */
@property (nonatomic, strong) DMImagePickerHandler *imagePickerHandler;
@end

@implementation DMMediaManager

+ (instancetype)shareManaegr {
    
    static dispatch_once_t onceToken;
    static DMMediaManager *manager;
    dispatch_once(&onceToken, ^{
        
        manager = [[DMMediaManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _showLoading = YES;
    }
    return self;
}

#pragma mark - =================== 文件选取和处理 =================

- (void)handleMediaWithParams:(NSDictionary *)params
                      headers:(NSDictionary *)headers
                     complete:(void (^)(NSString *result))completionHandler {
    
    DMNSLog(@"-------upload params----\n%@", params);
    
    if (![DMNetworkConfig shareConfig].path.length) {
        [DMNetworkConfig shareConfig].path = params[@"url"];
    }
    if ([params[@"timeoutInterval"] integerValue] > 0) {
        [DMNetworkConfig shareConfig].timeoutInterval = [params[@"timeoutInterval"] integerValue];
    }
    
    DMMediaType mediaType = [params[@"fileType"] isEqualToString:@"file-image"] ? DMMediaTypeImage : DMMediaTypeVideo;
    
    [self handleMediaWithType:mediaType
                       params:params
                      headers:headers
               handleProgress:nil
               uploadProgress:nil
                     complete:^(id  _Nullable responseObject, NSError * _Nonnull error) {
        
        if (!error) {
            if (completionHandler) {
                completionHandler([self jsonStringWithObj:responseObject]);
            }
        } else {
            if (completionHandler) {
                completionHandler([self jsonStringWithObj:@{@"success":@(0), @"info":error.localizedDescription}]);
            }
        }
    }];
}

- (void)handleMediaWithParams:(NSDictionary *)params
                      headers:(NSDictionary *)headers
               handleProgress:(void(^)(CGFloat progress))handleProgress
               uploadProgress:(void(^)(NSProgress * _Nonnull progress))uploadProgress
                     complete:(void (^)(id _Nullable responseObject, NSError * _Nonnull error))completionHandler {
    
    
    DMMediaType mediaType = [params[@"fileType"] isEqualToString:@"file-image"] ? DMMediaTypeImage : DMMediaTypeVideo;
    
    [self handleMediaWithType:mediaType
                       params:params
                      headers:headers
               handleProgress:handleProgress
               uploadProgress:uploadProgress
                     complete:completionHandler];
}

- (void)handleMediaWithType:(DMMediaType)type
                     params:(NSDictionary *)params
                    headers:(NSDictionary *)headers
             handleProgress:(void(^)(CGFloat progress))handleProgress
             uploadProgress:(void(^)(NSProgress * _Nonnull progress))uploadProgress
                   complete:(void (^)(id _Nullable responseObject, NSError * _Nonnull error))completionHandler {
    
    DMWeakSelf;
    
    [self.imagePickerHandler showAlertWithMideaType:type completeHandler:^(id  _Nullable result, DMMediaType type, NSError *error) {
        
        if (!result) {
            if (completionHandler) {
                completionHandler(nil, error);
            }
            return;
        }
        if (type == DMMediaTypeImage) {
            
            [weakSelf compressImage:result complete:^(UIImage * _Nonnull image, NSError * _Nonnull error) {
                if (image) {
                    DMNSLog(@"----compress complete success");
                    [weakSelf uploadImage:image
                                   params:params
                                  headers:headers
                                 progress:uploadProgress
                                 complete:^(id  _Nullable responseObject, NSError * _Nonnull error) {
                        
                        if (completionHandler) {
                            completionHandler(responseObject, error);
                        }
                    }];
                } else {
                    DMNSLog(@"----compress image complete failed");
                }
            }];
        } else {
            [weakSelf compressVideoURL:(NSURL *)result
                              progress:handleProgress
                              complete:^(AVAssetExportSessionStatus status, NSURL * _Nonnull outputURL, NSError * _Nonnull error) {
                if (!error) {
                    DMNSLog(@"----compress video success---- url:%@", outputURL.absoluteString);
                    [weakSelf uploadVideoURL:outputURL
                                      params:params
                                     headers:nil
                                    progress:uploadProgress
                                    complete:^(id  _Nullable responseObject, NSError * _Nonnull error) {
                        
                        if (completionHandler) {
                            completionHandler(responseObject, error);
                        }
                    }];
                } else {
                    DMNSLog(@"----compress video failed");
                }
            }];
        }
    }];
}

#pragma mark - =================== 上传图片 =================
- (void)uploadImage:(UIImage *)image
             params:(NSDictionary *)params
            headers:(NSDictionary *)headers
           progress:(void(^)(NSProgress * _Nonnull uploadProgress))progress
           complete:(void (^)(id _Nullable responseObject, NSError * _Nonnull error))completionHandler {
    
    if (![DMNetworkConfig shareConfig].path.length) {
        if (!params[@"url"]) {
            [[DMLoadingManager instance] showWithText:@"未配置上传路径"];
            
            return;
        } else {
            [DMNetworkConfig shareConfig].path = params[@"url"];
        }
    }
    if ([params[@"timeoutInterval"] integerValue] > 0) {
        [DMNetworkConfig shareConfig].timeoutInterval = [params[@"timeoutInterval"] integerValue];
    }
    
    
    NSAssert(image != nil, @"image is nil");
    if (!image) {
        return;
    }
    DMNSLog(@"----begin upload image---");
    DMWeakSelf;
    if (self.showLoading) {
        [[DMLoadingManager instance] showLoadingProgressText:@"图片上传中..."];
    }
    [self.enginer postReqeustHeaders:headers
                              params:params
                                data:UIImagePNGRepresentation(image)
                                 url:nil
                            fileType:params[@"fileType"]
                            fileName:@"file"
                            progress:^(NSProgress * _Nonnull uploadProgress) {
        
        dm_dispatch_main_async_safe(^{
            if (weakSelf.showLoading) {
                [DMLoadingManager instance].progress = uploadProgress.fractionCompleted;
                DMNSLog(@"--------upload image progress-----%f", uploadProgress.fractionCompleted);
                if (uploadProgress.fractionCompleted == 1.0) {
                    [[DMLoadingManager instance] changeLoadingText:@"图片上传成功"];
                }
            }
            if (progress) {
                progress(uploadProgress);
            }
        });
        
    } complete:^(NSError * _Nonnull error, id  _Nullable responseObject) {
        DMNSLog(@"----upload image finished \n response: %@   \n error: %@", responseObject, error);
        dm_dispatch_main_async_safe(^{
            if (weakSelf.showLoading) {
                [[DMLoadingManager instance] hide];
            }
            if (completionHandler) {
                completionHandler(responseObject, error);
            }
        });
        
    }];
}

#pragma mark - =================== 上传视频 =================
- (void)uploadVideoURL:(NSURL *)url
                params:(NSDictionary *)params
               headers:(NSDictionary *)headers
              progress:(void(^)(NSProgress * _Nonnull uploadProgress))progress
              complete:(void (^)(id _Nullable responseObject, NSError * _Nonnull))completionHandler {
    
    
    if (![DMNetworkConfig shareConfig].path.length) {
        if (!params[@"url"]) {
            [[DMLoadingManager instance] showWithText:@"未配置上传路径"];
            
            return;
        } else {
            [DMNetworkConfig shareConfig].path = params[@"url"];
        }
    }
    
    if ([params[@"timeoutInterval"] integerValue] > 0) {
        [DMNetworkConfig shareConfig].timeoutInterval = [params[@"timeoutInterval"] integerValue];
    }
    
    NSAssert(url != nil, @"video path is nil");
    
    DMWeakSelf;
    if (self.showLoading) {
        [[DMLoadingManager instance] showLoadingProgressText:@"视频上传中..."];
    }
    [self.enginer postReqeustHeaders:headers
                              params:params
                                data:nil
                                 url:url
                            fileType:params[@"fileType"]
                            fileName:@"file"
                            progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
        dm_dispatch_main_async_safe(^{
            if (weakSelf.showLoading) {
                
                [DMLoadingManager instance].progress = uploadProgress.fractionCompleted;
                DMNSLog(@"-----upload video----%f----progress----%f", uploadProgress.fractionCompleted, [DMLoadingManager instance].progress);
                if (uploadProgress.fractionCompleted == 1.0) {
                    [[DMLoadingManager instance] changeLoadingText:@"视频上传成功"];
                }
            }
            if (progress) {
                progress(uploadProgress);
            }
        });
    } complete:^(NSError * _Nonnull error, id  _Nullable responseObject) {
        dm_dispatch_main_async_safe(^{
            DMNSLog(@"----upload video finish \n response: %@   \n error: %@", responseObject, error);
            
            if (weakSelf.showLoading) {
                [[DMLoadingManager instance] hide];
            }
            if (completionHandler) {
                completionHandler(responseObject, error);
            }
        });
    }];
}

#pragma mark - ================ 图片压缩 ====================
- (void)compressImage:(UIImage *)image complete:(void (^)(UIImage *image, NSError * _Nonnull))completionHandler {
    
    DMWeakSelf;
    if (self.showLoading) {
        [[DMLoadingManager instance] show];
    }
    DMNSLog(@"----begin compress image----");
    [image dm_compressCompletionHandler:^(UIImage * _Nonnull image, NSError * _Nonnull error) {
        
        DMNSLog(@"---- compress image finished ----  error:%@",error);
        dm_dispatch_main_async_safe(^{
            
            if (weakSelf.showLoading) {
                [[DMLoadingManager instance] hide];
                [[DMLoadingManager instance] showWithText:@"图片处理完成"];
            }
            if (completionHandler) {
                completionHandler(image, error);
            }
        });
    }];
}


#pragma mark - ================ 视频压缩 ====================
- (void)compressVideoURL:(NSURL *)url
                progress:(void(^)(CGFloat progress))progressBlock
                complete:(void (^)(AVAssetExportSessionStatus status, NSURL *url,  NSError * _Nonnull error))completionHandler {
    
    DMNSLog(@"----begin compress video with url: %@", url.absoluteString);
    
    if ([url.scheme isEqualToString:@"assets-library"]) {
        
        [self compressVideoAsset:[AVURLAsset assetWithURL:url]
                        progress:progressBlock
                        complete:completionHandler];
    } else {
        if ([[NSFileManager defaultManager]fileExistsAtPath:url.path]) {
            [self compressVideoAsset:[AVURLAsset assetWithURL:url]
                            progress:progressBlock
                            complete:completionHandler];
        } else {
            NSError *error = [NSError errorWithDomain:AVFoundationErrorDomain
                                                 code:AVErrorExportFailed
                                             userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Can not find file in %@", url.absoluteString]}];
            completionHandler(AVAssetExportSessionStatusUnknown, url, error);
        }
    }
}


- (void)compressVideoAsset:(AVAsset *)asset
                  progress:(void(^)(CGFloat progress))progressBlock
                  complete:(void (^)(AVAssetExportSessionStatus status, NSURL *url, NSError * _Nonnull error))completionHandler {
    
    NSURL *outPath = [NSURL fileURLWithPath:[self createFile:@"540.mp4"]];
    
    DMAssetExportSessionManager *session = [[DMAssetExportSessionManager alloc] initWithAsset:asset preset:DMExportVideoPreset540P];
    session.outputURL = outPath;
    session.outputFileType = AVFileTypeMPEG4;
    //    session.delegate = self;
    
    DMWeakSelf;
    if (self.showLoading) {
        [[DMLoadingManager instance] showLoadingProgressText:@"视频处理中..."];
    }
    [session exportAsynWithProgress:^(CGFloat progress) {
        [weakSelf setupProgress:progress progressBlock:progressBlock];
    } completeHandler:^(AVAssetExportSessionStatus status, NSError * _Nullable error) {
        
        dm_dispatch_main_async_safe(^{
            
            if (status == AVAssetExportSessionStatusCompleted) {
                
                [weakSelf setupEstimatedExportSize:session.estimatedExportSize/1000.0];
                
                DMNSLog(@"Video export succeeded. video path:%@", session.outputURL);
                DMNSLog(@"The compressed file size is about %.2fMB", session.estimatedExportSize/1000.0);
            }
            
            if (weakSelf.showLoading) {
                [[DMLoadingManager instance] hide];
            }
            
            if (completionHandler) {
                completionHandler(status, session.outputURL, error);
            }
        });
    }];
}

/// 设置视频大小
/// @param size size description
- (void)setupEstimatedExportSize:(float)size {
    
    [self willChangeValueForKey:@"estimatedExportSize"];
    self->_estimatedExportSize = size;
    [self didChangeValueForKey:@"estimatedExportSize"];
}


/// 设置进度
/// @param progressValue 进度
/// @param progressBlock block
- (void)setupProgress:(CGFloat)progressValue progressBlock:(void(^)(CGFloat progress))progressBlock {
    
    [self changeProgress:progressValue progressBlock:progressBlock];
}

- (void)changeProgress:(CGFloat)progressValue progressBlock:(void(^)(CGFloat progress))progressBlock {
    
    [self willChangeValueForKey:@"progress"];
    self->_progress = progressValue;
    [self didChangeValueForKey:@"progress"];
    
    dm_dispatch_main_async_safe(^{
        DMNSLog(@"-------compress video progress----%f", progressValue);
        if (self.showLoading) {
            [DMLoadingManager instance].progress = progressValue;
            if (progressValue == 1.0) {
                [[DMLoadingManager instance] changeLoadingText:@"视频处理完成"];
            }
        }
        if (progressBlock) {
            progressBlock(progressValue);
        }
    });
}



- (NSString *)createFile:(NSString *)name {
    
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"tem_media"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    path = [path stringByAppendingPathComponent:name];
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:nil];
    }
    return path;
}

- (void)cancelAllReqeust {
    
    [self.enginer cancelAllRequest];
    [[DMLoadingManager instance] hide];
}

- (NSString *)jsonStringWithObj:(id)obj {
    
    DMNSLog(@"-------upload response------\n%@", obj);
    if (!obj) {
        return nil;
    }
    
    if([obj isKindOfClass:[NSData class]]){
        
        return [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        
        DMNSLog(@"-------upload success-------");
        NSError *parseError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:0 error:&parseError];
        NSString *jsonString = nil;
        if (jsonData) {
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        DMNSLog(@"----jsonString---%@", jsonString);
        return jsonString;
    }
    
    DMNSLog(@"-------response data format is error-------");
    return nil;
}

- (DMNetworkEnginer *)enginer {
    if (!_enginer) {
        _enginer = [[DMNetworkEnginer alloc] init];
    }
    return _enginer;
}

- (DMImagePickerHandler *)imagePickerHandler {
    if (!_imagePickerHandler) {
        _imagePickerHandler = [[DMImagePickerHandler alloc] init];
    }
    return _imagePickerHandler;
}
@end
