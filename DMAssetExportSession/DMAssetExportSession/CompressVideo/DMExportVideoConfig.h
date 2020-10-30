//
//  DMExportVideoConfig.h
//  ExportVideo
//
//  Created by yao wang on 2020/9/12.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import "DMDefine.h"
#ifndef DMExportVideoConfig_h
#define DMExportVideoConfig_h


/// 读取asset时，输出音频配置
inline static NSDictionary *readAssetAudioOutputConfig()
{
    return @{
        AVFormatIDKey: [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM], //录音格式
        AVSampleRateKey: @44100, //录音采样率（HZ）
        AVNumberOfChannelsKey: @2, //录音通道数(1或2)，要转换成mp3格式必须为双通道
        AVLinearPCMBitDepthKey: @16, //设置录制音频的每个样点的位数 线性采样位数  8、16、24、32
        AVLinearPCMIsBigEndianKey: @NO, //设置录制音频采用高位优先的记录格式
        AVLinearPCMIsFloatKey: @NO, //是否浮点采样
        AVLinearPCMIsNonInterleaved: @NO
    };
}

/// 写入音频是，输出配置
inline static NSDictionary *writeAudioOutputConfig()
{
    
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    return @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVChannelLayoutKey: [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)],
        AVNumberOfChannelsKey: @2,
        AVSampleRateKey: @44100,
        AVEncoderBitRateKey: @128000
    };
}

inline static NSDictionary *readAssetVideoOutputConfig(void)
{
    return @{
        (id)kCVPixelBufferPixelFormatTypeKey     : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],
        (id)kCVPixelBufferIOSurfacePropertiesKey : [NSDictionary dictionary]
    };
}


inline static CGSize exportSessionPresetSize(DMExportVideoPreset preset)
{
    CGSize size;
    switch (preset) {
        case DMExportVideoPreset240P:
            size = CGSizeMake(240, 360);
            break;
        case DMExportVideoPreset360P:
            size = CGSizeMake(360, 480);
            break;
        case DMExportVideoPreset480P:
            size = CGSizeMake(480, 640);
            break;
        case DMExportVideoPreset540P:
            size = CGSizeMake(540, 960);
            break;
        case DMExportVideoPreset1080P:
            size = CGSizeMake(1080, 1920);
            break;
        case DMExportVideoPreset2K:
            size = CGSizeMake(1440, 2560);
            break;
        case DMExportVideoPreset4K:
            size = CGSizeMake(2160, 3840);
            break;
        case DMExportVideoPreset720P:
        default:
            size = CGSizeMake(720, 1280);
            break;
    }
    return size;
}

inline static DMExportVideoPreset exportVideoPresetFromSize(CGSize size)
{
    if (size.width > size.height) {
        CGFloat width = size.width;
        size.width = size.height;
        size.height = width;
    }
    
    if (size.width <= 240 && size.height <= 360) {
        return DMExportVideoPreset240P;
    }
    if (size.width <= 360 && size.height <= 480) {
        return DMExportVideoPreset360P;
    }
    if (size.width <= 480 && size.height <= 640) {
        return DMExportVideoPreset480P;
    }
    if (size.width <= 540 && size.height <= 960) {
        return DMExportVideoPreset540P;
    }
    if (size.width <= 720 && size.height <= 1280) {
        return DMExportVideoPreset720P;
    }
    if (size.width <= 1080 && size.height <= 1920) {
        return DMExportVideoPreset1080P;
    }
    if (size.width <= 1440 && size.height <= 2560) {
        return DMExportVideoPreset2K;
    }
    if (size.width <= 2160 && size.height <= 3840) {
        return DMExportVideoPreset4K;
    }
    return DMExportVideoPreset540P;
}

inline static unsigned long exportVideoPresetBitrate(DMExportVideoPreset preset)
{
    // 根据这篇文章Video Encoding Settings for H.264 Excellence http://www.lighterra.com/papers/videoencodingh264/#maximumkeyframeinterval
    // Video Bitrate Calculator https://www.dr-lex.be/info-stuff/videocalc.html
    
    unsigned long bitrate = 0;
    switch (preset) {
        case DMExportVideoPreset240P:
            bitrate = 450000;
            break;
        case DMExportVideoPreset360P:
            bitrate = 770000;
            break;
        case DMExportVideoPreset480P:
            bitrate = 1200000;
            break;
        case DMExportVideoPreset540P:
            bitrate = 2074000;
            break;
        case DMExportVideoPreset1080P:
            bitrate = 7900000;
            break;
        case DMExportVideoPreset2K:
            bitrate = 13000000;
            break;
        case DMExportVideoPreset4K:
            bitrate = 31000000;
            break;
        case DMExportVideoPreset720P:
        default:
            bitrate = 3500000;
            break;
    }
    return bitrate;
}



inline static NSDictionary *writeVideoConfig(CGSize size, DMExportVideoPreset preset) {
    
    float ratio = 1;
    CGSize presetSize = exportSessionPresetSize(preset);
    CGSize videoSize = size;
    if (videoSize.width > videoSize.height) {
        ratio = videoSize.width / presetSize.height;
    } else {
        ratio = videoSize.width / presetSize.width;
    }
    
    if (ratio > 1) {
        videoSize = CGSizeMake(videoSize.width / ratio, videoSize.height / ratio);
    }
    
    DMExportVideoPreset realPreset = exportVideoPresetFromSize(videoSize);
    unsigned long bitrate = exportVideoPresetBitrate(realPreset);
    
    NSString *codeType = nil;
    if (@available(iOS 11.0, *)) {
        codeType = AVVideoCodecTypeH264;
    } else {
        codeType = AVVideoCodecH264;
    }
    return @{
    
        AVVideoCodecKey: codeType,
        AVVideoWidthKey:[NSNumber numberWithInteger:videoSize.width],
        AVVideoHeightKey:[NSNumber numberWithInteger:videoSize.height],
        AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,
        AVVideoCompressionPropertiesKey: @
        {
            AVVideoAverageBitRateKey: [NSNumber numberWithUnsignedLong:bitrate],
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
            AVVideoAllowFrameReorderingKey:@NO,
            AVVideoExpectedSourceFrameRateKey:@30
        },
    };
}


#endif /* DMExportVideoConfig_h */
