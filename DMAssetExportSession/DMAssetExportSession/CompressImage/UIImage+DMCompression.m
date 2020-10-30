//
//  UIImage+DMCompress.m
//  ExportVideo
//
//  Created by yao wang on 2020/9/16.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import "UIImage+DMCompression.h"
#import "DMDefine.h"

static CGFloat const MAXQUALITY = 0.8;  //初始最高压缩质量系数
static CGFloat const MINQUALITY = 0.4;  //初始最低压缩质量系数
static CGFloat const MAXSIZE = 500; //图片限定大小，单位byte


@implementation UIImage (DMCompression)

#pragma mark - 图片压缩

- (void)DM_compressCompletionHandler:(void (^)(UIImage * _Nonnull, NSError * _Nonnull))completionHandler {
    
    [self dm_compressWithMaxBytes:MAXSIZE * 1024 completionHandler:completionHandler];
}

- (void)dm_compressWithMaxBytes:(NSInteger)maxBytes
              completionHandler:(void(^)(UIImage *image, NSError *error))completionHandler{

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        CGFloat compression = 1;
        NSData *data = UIImageJPEGRepresentation(self, compression);
        CGSize size = [self sizeWithImage:self];
        if (!(size.width == self.size.width && size.height == self.size.height)) {

            data = [self resizeImageData:data size:size];
            if ([self handleData:data
                        maxBytes:maxBytes
               completionHandler:completionHandler]) {
                return;
            }
        }
    
        data = [self dataWithImage:[UIImage imageWithData:data] maxBytes:maxBytes];
        if ([self handleData:data
                    maxBytes:maxBytes
           completionHandler:completionHandler]) {
            return;
        }
        
//        DMNSLog(@"-------image size-----%uKB", data.length / 1024);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler([UIImage imageWithData:data], nil);
            }
        });
    });
}

///**
// 根据图片Size返回对应图片，为降低CPU消耗使用Image I/O
//
// @return  图片
// */
//- (NSData *)convertData:(NSData *)sourceData size:(CGSize)imgSize maxBytes:(NSInteger)maxBytes {
//
//    NSData *data = sourceData;
//    NSUInteger lastDataLength = 0;
//
//    while (data.length > maxBytes && data.length != lastDataLength) {
//
//        lastDataLength = data.length;
//        CGFloat ratio = (CGFloat)maxBytes / data.length;
//        CGSize size = CGSizeMake((NSUInteger)(imgSize.width * sqrtf(ratio)),
//                                 (NSUInteger)(imgSize.height * sqrtf(ratio))); // Use NSUInteger to prevent white blank
//
//        data = [self covertData:data size:size];
//    }
//
//    return data;
//}

- (BOOL)handleData:(NSData *)data
          maxBytes:(NSInteger)maxBytes
 completionHandler:(void(^)(UIImage *image, NSError *error))completionHandler{
    
    if (data.length <= maxBytes) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler([UIImage imageWithData:data], nil);
            }
        });
        return YES;
    }
    return NO;
}

- (NSData *)dataWithImage:(UIImage *)image maxBytes:(NSInteger)maxBytes{
    
    CGFloat max = MAXQUALITY;
    CGFloat min = MINQUALITY;
    CGFloat compression = 1.0;
    NSData *data;
    for (int i = 0; i <= 6; i++) {
        compression = (max + min) / 2;
        data = UIImageJPEGRepresentation(image, compression);
        if (data.length <= maxBytes) {
            break;
        }
        if (data.length < maxBytes * 0.9) {
            min = compression;
        } else if (data.length > maxBytes) {
            max = compression;
        } else {
            break;
        }
    }
    return data;
}

- (NSData *)resizeImageData:(NSData *)data size:(CGSize)imgSize {
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
    
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef) @{
        (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
        (NSString *)kCGImageSourceThumbnailMaxPixelSize : @(MAX(imgSize.width,imgSize.height)),
        (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES,
    });
    CFRelease(source);
    CFRelease(provider);
    
    if (!imageRef) {
        
        CFRelease(imageRef);
        return data;
    } else {
        
        UIImage *resultImage = [UIImage imageWithCGImage:imageRef];
        CFRelease(imageRef);
        return UIImageJPEGRepresentation(resultImage, 1.0);
    }
}

/**
 根据图片尺寸和对应策略得到图片Size
 
 @return  图片Size
 */
- (CGSize)sizeWithImage:(UIImage *)image {
    
    CGFloat scaleW  = 1.0;
    CGFloat scaleH  = 1.0;
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    if (imageWidth > kScreenW) {
        scaleW  = sqrt(imageWidth / kScreenW);
    }
    if (imageHeight > kScreenH) {
        scaleH  = sqrt(imageHeight / kScreenH);
    }
    CGFloat scale = MAX(1.0, MAX(scaleW, scaleH));

    return CGSizeMake(imageWidth / scale, imageHeight / scale);
}


// 返回正常方向图片
- (UIImage *)fixOrientation {
    
    // 判断图片方向是否正确，正确则返回
    UIImageOrientation orientation = (UIImageOrientation)self.imageOrientation;
    if (orientation == UIImageOrientationUp) {
        return self;
    }
    // 计算适当的变换使图像垂直
    // 两步:如果是左/右/向下旋转，如果是镜像则翻转
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (orientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (orientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // 将底层的CGImage绘制到一个新的Context中，并转换为正确方向
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    // 创建一个新的UIImage
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}


- (NSString *)tmpImage {
    
    NSString *videoPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"tem_image"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:videoPath]) {
        [fileManager createDirectoryAtPath:videoPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return videoPath;
}

- (NSString *)createFile:(NSString *)name {
    
    NSString *path = [[self tmpImage] stringByAppendingPathComponent:name];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:nil];
    }
    return path;
}

@end
