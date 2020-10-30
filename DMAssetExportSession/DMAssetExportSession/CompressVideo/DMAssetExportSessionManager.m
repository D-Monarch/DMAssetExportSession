//
//  DMAssetExportSession.m
//  ExportVideo
//
//  Created by yao wang on 2020/9/2.
//  Copyright © 2020 lionbridgecapital. All rights reserved.
//

#import "DMAssetExportSessionManager.h"
#import "AVAsset+DMAssetDegress.h"
#import "DMExportVideoConfig.h"

@interface DMAssetExportSessionManager(){
    
    dispatch_queue_t _videoQueue;
    dispatch_queue_t _audioQueue;
    dispatch_group_t _dispatchGroup;
    Float64 _totalDuration;
    NSError *_error;
}

@property (nonatomic, strong) AVAssetReader *assetReader;
@property (nonatomic, strong) AVAssetReaderTrackOutput *audioOutput;
@property (nonatomic, strong) AVAssetReaderOutput *videoOutput;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor;

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, assign) CGSize inputBufferSize;

@property (nonatomic,assign) DMExportVideoPreset preset;

@property (nonatomic, assign) CMTimeRange timeRange;

@property (nonatomic,assign) BOOL cancelled;
@property (nonatomic,assign) BOOL needsLeaveAudio;
@property (nonatomic,assign) BOOL needsLeaveVideo;

@property (nonatomic, copy) DMProgress progressBlock;

@end



@implementation DMAssetExportSessionManager

-(instancetype)init {
    self = [super init];
    
    if (self) {
        _videoQueue = dispatch_queue_create("com.lionbridge.videoQueue", nil);
        _audioQueue = dispatch_queue_create("com.lionbridge.audioQueue", nil);
        _dispatchGroup = dispatch_group_create();
        _timeRange = CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity);
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url preset:(DMExportVideoPreset)preset {
    return [self initWithAsset:[AVAsset assetWithURL:url] preset:preset];
}

/// 初始化方法
/// @param asset AVAsset 对象
/// @param preset 分辨率
- (instancetype)initWithAsset:(AVAsset *)asset preset:(DMExportVideoPreset)preset {
    self = [self init];
    if (self) {
        _asset = asset;
        _preset = preset;
    }
    return self;
}

/// 开始压缩
/// @param completeHandler complete
- (void)exportAsynWithProgress:(DMProgress)progress completeHandler:(DMCompletionHandler)completeHandler {
    
    NSParameterAssert(completeHandler != nil);
    
    if (!self.outputURL) {
        
        _error = [NSError errorWithDomain:AVFoundationErrorDomain
                                     code:AVErrorExportFailed
                                 userInfo:@{NSLocalizedDescriptionKey: @"Output URL is empty"}];
        completeHandler(self.status, _error);
        return;
    }
        
    _cancelled = NO;

    _progressBlock = progress;
    
    if (!self.outputFileType) {
        self.outputFileType = AVFileTypeMPEG4;
    }
    
    
    if ([NSFileManager.defaultManager fileExistsAtPath:self.outputURL.path]) {
        [NSFileManager.defaultManager removeItemAtURL:self.outputURL error:nil];
    }
    
    NSError *readerError;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:self.asset error:&readerError];
    if (readerError) {
        _error = readerError;
        completeHandler(self.status, _error);
        return;
    }
    
    NSError *writerError;
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:self.outputURL fileType:self.outputFileType error:&writerError];
    if (writerError) {
        _error = writerError;
        completeHandler(self.status, _error);
        return;
    }
    self.assetReader = reader;
    self.assetWriter = writer;
    
    if (CMTIME_IS_VALID(self.timeRange.duration) && !CMTIME_IS_POSITIVE_INFINITY(self.timeRange.duration)) {
        _totalDuration = CMTimeGetSeconds(self.timeRange.duration);
    } else {
        _totalDuration = CMTimeGetSeconds(self.asset.duration);
    }
    self.assetReader.timeRange = self.timeRange;
    self.assetWriter.shouldOptimizeForNetworkUse = NO;
    self.assetWriter.metadata = self.metadata;
    
    [self setAudioTrack];
    [self setVideoTrack];
    
    if (![_assetReader startReading]) {
        _error = _assetReader.error;
        completeHandler(self.status, _error);
        return;
    }
    
    if (![_assetWriter startWriting]) {
        _error = _assetWriter.error;
        completeHandler(self.status, _error);
        return;
    }
    
    [self.assetWriter startSessionAtSourceTime:self.timeRange.start];
    
    [self beginReadWriteOnAudio];
    [self beginReadWriteOnVideo];
    
    __block NSError *tempError = _error;
    
    dispatch_group_notify(_dispatchGroup, dispatch_get_main_queue(), ^{
        if (tempError == nil) {
            tempError = self.assetWriter.error;
        }
        if (tempError == nil && self.assetWriter.status != AVAssetWriterStatusCancelled) {
            
            [self.assetWriter finishWritingWithCompletionHandler:^{
                dm_dispatch_main_async_safe(^{

                    tempError = self.assetWriter.error;
                    [self complete:completeHandler error:tempError];
                });
            }];
        } else {
            [self complete:completeHandler error:tempError];
        }
    });
}

/// 计算大小
- (float)estimatedExportSize {
    
    unsigned long audioBitrate = [[writeAudioOutputConfig() objectForKey:AVEncoderBitRateKey] unsignedLongValue];
    unsigned long videoBitrate = 0;
    
    NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
    if (videoTracks.count > 0) {
        AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
        videoBitrate = [[[writeVideoConfig(videoTrack.naturalSize, self.preset) objectForKey:AVVideoCompressionPropertiesKey] objectForKey:AVVideoAverageBitRateKey] unsignedLongValue];
    }
    
    
    Float64 duration = 0;
    if (CMTIME_IS_VALID(self.timeRange.duration) && !CMTIME_IS_POSITIVE_INFINITY(self.timeRange.duration)) {
        duration = CMTimeGetSeconds(self.timeRange.duration);
    } else {
        duration = CMTimeGetSeconds(self.asset.duration);
    }
    
    if (audioBitrate > 0 && videoBitrate > 0) {
        //    （音频编码率（KBit为单位）/8 + 视频编码率（KBit为单位）/8）× 影片总长度（秒为单位）= 文件大小（KB为单位）
        float compressedSize = (audioBitrate/1000.0/8.0 + videoBitrate/1000.0/8.0) * duration;
        return compressedSize;
    }
    return 0;
}



/// 音频设置
- (void)setAudioTrack {
    
    NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
    if (!audioTracks.count) {
        self.audioOutput = nil;
        return;
    }
    
    self.audioOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:[self.asset tracksWithMediaType:AVMediaTypeAudio].firstObject outputSettings:readAssetAudioOutputConfig()];
    self.audioOutput.alwaysCopiesSampleData = NO;//改进性能

    //音频设置
    if ([self.assetReader canAddOutput:self.audioOutput]) {
        [self.assetReader addOutput:self.audioOutput];
    }
    
    self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:writeAudioOutputConfig()];
    self.audioInput.expectsMediaDataInRealTime = NO;
    if ([self.assetWriter canAddInput:self.audioInput]) {
        [self.assetWriter addInput:self.audioInput];
    }
}

/// 视频设置
- (void)setVideoTrack {
    
    NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
    if (!videoTracks.count) {
        self.videoOutput = nil;
        return;
    }
    //视频设置
    AVVideoComposition *videoComposition = [self defaultVideoCompostition];
    if (videoComposition) {
        NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetReaderVideoCompositionOutput *videoCompositionOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:videoTracks videoSettings:readAssetVideoOutputConfig()];
        videoCompositionOutput.alwaysCopiesSampleData = NO;
        videoCompositionOutput.videoComposition = videoComposition;
        
        self.videoOutput = videoCompositionOutput;
        self.inputBufferSize = videoComposition.renderSize;
    } else {
        NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
        self.videoOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTracks.firstObject outputSettings:readAssetVideoOutputConfig()];
        self.videoOutput.alwaysCopiesSampleData = NO;

        self.inputBufferSize = ((AVAssetTrack *)([self.asset tracksWithMediaType:AVMediaTypeVideo].firstObject)).naturalSize;
    }
    
    if ([self.assetReader canAddOutput:self.videoOutput]) {
        [self.assetReader addOutput:self.videoOutput];
    }
    
    self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:writeVideoConfig(_inputBufferSize, _preset)];
    self.videoInput.expectsMediaDataInRealTime = NO;
    if ([self.assetWriter canAddInput:self.videoInput]) {
        [self.assetWriter addInput:self.videoInput];
    }
    
    NSDictionary *pixelBufferAttributes = @{
        (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
        (id)kCVPixelBufferWidthKey: @(self.inputBufferSize.width),
        (id)kCVPixelBufferHeightKey: @(self.inputBufferSize.height),
        (id)kCVPixelFormatOpenGLESCompatibility: @YES
    };
    self.videoPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoInput sourcePixelBufferAttributes:pixelBufferAttributes];
}

- (AVMutableVideoComposition *)defaultVideoCompostition {
    
    AVMutableVideoComposition *videoComposition = [self.asset videoComposition];
    if (videoComposition) {
        AVAssetTrack *videoTrack = [[self.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        float trackFrameRate = [videoTrack nominalFrameRate];
        if (trackFrameRate == 0) {
            trackFrameRate = 30;
        }
        videoComposition.frameDuration = CMTimeMake(1, trackFrameRate);
    }
    return videoComposition;
}


/// 音频处理
- (void)beginReadWriteOnAudio {
    if (_audioInput != nil) {
        dispatch_group_enter(_dispatchGroup);
        _needsLeaveAudio = YES;
        __weak typeof(self) wSelf = self;
        [_audioInput requestMediaDataWhenReadyOnQueue:_audioQueue usingBlock:^{
            __strong typeof(self) strongSelf = wSelf;
            BOOL shouldReadNextBuffer = YES;
            
            while (strongSelf.audioInput.isReadyForMoreMediaData && shouldReadNextBuffer && !strongSelf.cancelled) {
                
                CMSampleBufferRef audioBuffer = [strongSelf.audioOutput copyNextSampleBuffer];
                
                if (audioBuffer != nil) {
                    
                    shouldReadNextBuffer = [strongSelf.audioInput appendSampleBuffer:audioBuffer];
                    CMTime time = CMSampleBufferGetPresentationTimeStamp(audioBuffer);
                    CFRelease(audioBuffer);
                    [strongSelf didAppendToInput:strongSelf.audioInput atTime:time];
                } else {
                    shouldReadNextBuffer = NO;
                }
            }
            
            if (!shouldReadNextBuffer) {
                [strongSelf inputComplete:strongSelf.audioInput error:nil];
                if (strongSelf.needsLeaveAudio) {
                    strongSelf.needsLeaveAudio = NO;
                    dispatch_group_leave(strongSelf->_dispatchGroup);
                }
            }
        }];
    }
}

/// 视频处理
- (void)beginReadWriteOnVideo {
    if (_videoInput != nil) {
        dispatch_group_enter(_dispatchGroup);
        _needsLeaveVideo = YES;
        __weak typeof(self) weakSelf = self;
        [_videoInput requestMediaDataWhenReadyOnQueue:_videoQueue usingBlock:^{
            
            BOOL shouldReadNextBuffer = YES;
            __strong typeof(self) strongSelf = weakSelf;
            
            while (strongSelf.videoInput.isReadyForMoreMediaData &&
                   shouldReadNextBuffer &&
                   !strongSelf.cancelled) {
                
                CMSampleBufferRef videoBuffer = [strongSelf.videoOutput copyNextSampleBuffer];
                
                if (videoBuffer != nil) {
                    CMTime time = CMSampleBufferGetPresentationTimeStamp(videoBuffer);
                    time = CMTimeSubtract(time, strongSelf.timeRange.start);
                    CVPixelBufferRef renderBuffer = NULL;
                    if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(assetSession:renderFrame:presentationTime:toBuffer:)])
                    {
                        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(videoBuffer);
                        CVReturn status = CVPixelBufferPoolCreatePixelBuffer(NULL, self.videoPixelBufferAdaptor.pixelBufferPool, &renderBuffer);
                        
                        if (status == kCVReturnSuccess){
                            
                            [strongSelf.delegate assetSession:self
                                                  renderFrame:pixelBuffer
                                             presentationTime:time
                                                     toBuffer:renderBuffer];
                        } else {
                            strongSelf->_error = [NSError errorWithDomain:AVFoundationErrorDomain
                                                                     code:AVErrorExportFailed
                                                                 userInfo:@{NSLocalizedDescriptionKey:@"Failed to create pixel buffer"}];
                        }
                    }
                    
                    if (renderBuffer) {
                        shouldReadNextBuffer = [strongSelf.videoPixelBufferAdaptor appendPixelBuffer:renderBuffer withPresentationTime:time];
                        CVPixelBufferRelease(renderBuffer);
                    }else {
                        shouldReadNextBuffer = [strongSelf.videoInput appendSampleBuffer:videoBuffer];
                    }
                    
                    CFRelease(videoBuffer);
                    
                    [strongSelf didAppendToInput:strongSelf.videoInput atTime:time];
                    
                } else {
                    shouldReadNextBuffer = NO;
                }
            }
            
            if (!shouldReadNextBuffer) {
                [strongSelf inputComplete:strongSelf.videoInput error:nil];
                
                if (strongSelf.needsLeaveVideo) {
                    strongSelf.needsLeaveVideo = NO;
                    dispatch_group_leave(strongSelf->_dispatchGroup);
                }
            }
        }];
        
    }
}

- (void)inputComplete:(AVAssetWriterInput *)input error:(NSError *)error {
    if (_assetReader.status == AVAssetReaderStatusFailed) {
        _error = _assetReader.error;
    } else if (error != nil) {
        _error = error;
    }
    
    if (_assetWriter.status != AVAssetWriterStatusCancelled) {
        [input markAsFinished];
    }
}

- (void)didAppendToInput:(AVAssetWriterInput *)input atTime:(CMTime)time {
    if (input == _videoInput || _videoInput == nil) {
        float progress = _totalDuration == 0 ? 1 : CMTimeGetSeconds(time) / _totalDuration;
        [self setExportProgress:progress];
    }
}


/// 进度设置
/// @param progress 进度
- (void)setExportProgress:(float)progress {
    
    __weak typeof(self) weakSelf = self;
    dm_dispatch_main_async_safe(^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf changeProgress:progress];
    });
}

- (void)changeProgress:(CGFloat)progress {
    
    [self willChangeValueForKey:@"progress"];
    self->_progress = progress;
    [self didChangeValueForKey:@"progress"];
    
    if (_progressBlock) {
        _progressBlock(progress);
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(assetSession:progress:)]) {
        [self.delegate assetSession:self progress:progress];
    }
}

- (void)complete:(DMCompletionHandler)completionHandler error:(NSError *)error
{
    if (!_cancelled) {
        [self setExportProgress:1];
    }
    
    if (self.assetWriter.status == AVAssetWriterStatusFailed || self.assetWriter.status == AVAssetWriterStatusCancelled) {
        
        [NSFileManager.defaultManager removeItemAtURL:self.outputURL error:nil];
    }
    
    if (completionHandler) {
        completionHandler(self.status, _error);
    }
    
    [self resetAllDatas];
}


/// 视频导出状态
- (AVAssetExportSessionStatus)status
{
    switch (self.assetWriter.status)
    {
        case AVAssetWriterStatusUnknown:
            return AVAssetExportSessionStatusUnknown;
        case AVAssetWriterStatusWriting:
            return AVAssetExportSessionStatusExporting;
        case AVAssetWriterStatusFailed:
            return AVAssetExportSessionStatusFailed;
        case AVAssetWriterStatusCompleted:
            return AVAssetExportSessionStatusCompleted;
        case AVAssetWriterStatusCancelled:
            return AVAssetExportSessionStatusCancelled;
        default:
            break;
    }
}

/// 取消压缩
- (void)cancel {
    
    _cancelled = YES;
    dispatch_sync(_videoQueue, ^{
        if (_needsLeaveVideo) {
            _needsLeaveVideo = NO;
            dispatch_group_leave(_dispatchGroup);
        }
        
        dispatch_sync(_audioQueue, ^{
            if (_needsLeaveAudio) {
                _needsLeaveAudio = NO;
                dispatch_group_leave(_dispatchGroup);
            }
        });
        
        [_assetReader cancelReading];
        [_assetWriter cancelWriting];
    });
}


/// 清除数据
- (void)resetAllDatas {
    
    _error = nil;
    _progress = 0;
    _inputBufferSize = CGSizeZero;
    self.assetReader = nil;
    self.videoOutput = nil;
    self.audioOutput = nil;
    self.assetWriter = nil;
    self.videoInput = nil;
    self.videoPixelBufferAdaptor = nil;
    self.audioInput = nil;
}

#pragma mark - ================   Getter ===============


- (NSError *)error {
    if (_error) {
        return _error;
    } else {
        return self.assetWriter.error ? : self.assetReader.error;
    }
}

@end
