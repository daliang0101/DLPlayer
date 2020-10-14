//
//  DLAVSynchronizerBase.m
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLAVSynchronizerBase.h"
#import "DLAVSynchronizerPrivateProtocol.h"
#import "DLDecoder.h"
#import "DLAVFrame.h"

static char * const kDecodeFrameSerialQuueue = "kDecodeFrameSerialQuueue";
static NSTimeInterval const kThresholdCorrectionTime = 1.0;
static NSTimeInterval const kAudioSpeedupToFillSilenceDataThresholdTime = 0.1;
static NSTimeInterval const kAudioDelayToBeDropedThresholdTime = 0.1;

static NSInteger const kUpdateHudOnVideoFrameFrequency = 6;

#define LOCAL_MIN_BUFFERED_DURATION   0.2       // 本地 缓冲 最小时长
#define LOCAL_MAX_BUFFERED_DURATION   0.4       // 本地 缓冲 最大时长
#define NETWORK_MIN_BUFFERED_DURATION 2.0       // 网络 缓冲 最小时长
#define NETWORK_MAX_BUFFERED_DURATION 4.0       // 网络 缓冲 最大时长

@interface DLAVSynchronizerBase () <DLSynchronizerPrivateProtocol>

@end

@implementation DLAVSynchronizerBase

SYNC_PROPERTIES_COMPILEOPTIONS_SETUP

#pragma mark - Init

- (instancetype)init {
    if (self = [super init]) {
        _isParsing = NO;
        _isEOF = NO;
    }
    return self;
}
- (void)dealloc {
    if (_dispatchQueue) {
        _dispatchQueue = NULL;
    }
}

#pragma mark - DLAVSynchronizerProtocol's public

- (NSUInteger)videoWidth {
    return self.decoder.frameWidth;
}
- (NSUInteger)videoHeight {
    return self.decoder.frameHeight;
}
- (DLVideoFrameFormat)videoFrameFormat {
    return [self.decoder getFrameFormat];
}

- (BOOL)start:(NSString *_Nullable)path {
    self.isParsing = YES;
    __weak typeof(self) weakSelf = self;
    self.decoder.interruptCallback = ^BOOL { // 解码中断回调
        __strong typeof(weakSelf) strongSelf = weakSelf;
        return strongSelf ? [strongSelf interruptDecoder] : YES;
    };
    self.decoder.eofCallback = ^(BOOL eof) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf willChangeValueForKey:@"isEOF"];
        strongSelf->_isEOF = eof;
        [strongSelf didChangeValueForKey:@"isEOF"];
    };
    
    NSError *error = nil;
    [self.decoder openFile:path error:&error];
    self.isParsing = NO;
    return [self OpenFileFinishedHandle:error];
}

- (void)run {
    if (_running) {
        return;
    }
    if (!self.decoder.validVideo && !self.decoder.validAudio) {
        return;
    }
    if (_interrupted)   {
        return;
    }
    
    self.running = YES;
    self.interrupted = NO;
    self.tickCorrectionTime = 0;
    self.tickCounter = 0;
    
    [self asyncDecodeFrames];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self tick];
    });
}

- (void)pause {
    [self willChangeValueForKey:@"buffered"];
    self.buffered = NO;
    [self didChangeValueForKey:@"buffered"];
    
    self.running = NO;
}

- (void)stop {
    [self pause];
    if (_dispatchQueue) {
        dispatch_async(_dispatchQueue, ^{
            [self freeBufferedFrames];
            [self.decoder closeFile];
        });
    }
}

- (void)fillAudioData:(float *_Nullable)outData
            numFrames:(UInt32 )numFrames
          numChannels:(UInt32 )numChannels
{
    if (_buffered) {
        memset(outData, 0, numFrames * numChannels * sizeof(float));
        return;
    }
    @autoreleasepool
    {
        while (numFrames > 0)
        {
            if (!_currentAudioFrame)
            {
                @synchronized(_audioFrames)
                {
                    NSUInteger count = _audioFrames.count;
                    if (count > 0)
                    {
                        id<DLAudioFrameProtocol> frame = _audioFrames[0];
                        
                        if (self.decoder.validVideo) {
                            const CGFloat delta = _moviePosition - frame.position;
                            if (delta < -kAudioSpeedupToFillSilenceDataThresholdTime) {
                                memset(outData, 0, numFrames * numChannels * sizeof(float));
                                break;
                            }
                            
                            [_audioFrames removeObjectAtIndex:0];
                            
                            if (delta > kAudioDelayToBeDropedThresholdTime && count > 1) {
                                continue;
                            }
                        } else {
                            [_audioFrames removeObjectAtIndex:0];
                            self.moviePosition = frame.position;
                            self.bufferedDuration -= frame.duration;
                        }
                        
                        self.currentAudioFramePos = 0;
                        self.currentAudioFrame = frame.samples;
                    }
                }
            }
            
            if (_currentAudioFrame)
            {
                const void *bytes = (Byte *)_currentAudioFrame.bytes + _currentAudioFramePos;
                const NSUInteger bytesLeft = (_currentAudioFrame.length - _currentAudioFramePos);
                const NSUInteger frameSizeOf = numChannels * sizeof(float);
                const NSUInteger bytesToCopy = MIN(numFrames * frameSizeOf, bytesLeft);
                const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
                memcpy(outData, bytes, bytesToCopy);
                numFrames -= framesToCopy;
                outData += framesToCopy * numChannels;
                
                if (bytesToCopy < bytesLeft)    {
                    _currentAudioFramePos += bytesToCopy;
                }   else {
                    _currentAudioFrame = nil;
                }
            } else {
                memset(outData, 0, numFrames * numChannels * sizeof(float));
                break;
            }
        }
    }
}

- (BOOL)handleMemoryWarningOnPlayMode:(BOOL)isPlay {
    if (isPlay) {
        if (_maxBufferedDuration > 0) {
            _minBufferedDuration = _maxBufferedDuration = 0;
            NSLog(@"didReceiveMemoryWarning, disable buffering and continue playing");
            return YES;
        } else {
            // force ffmpeg to free allocated memory
            [self.decoder closeFile];
            [self.decoder openFile:nil error:nil];  // 传递nil， 内部会被断言拦截，以便调试
            // 展示内存警告弹框（调试用，这里应该加调试宏，只在Debug模式下启用）
//            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
//                                        message:NSLocalizedString(@"Out of memory", nil)
//                                       delegate:nil
//                              cancelButtonTitle:NSLocalizedString(@"Close", nil)
//                              otherButtonTitles:nil] show];
        }
    } else {
        [self freeBufferedFrames];  // 释放各缓冲队列中的帧
        [self.decoder closeFile];       // 关闭文件资源
        [self.decoder openFile:nil error:nil];  // 开启断言拦截
    }
    return NO;
}

- (void)updateOnType:(DLAVSnycUpdateProgressType)type
        updateValue:(float)updateValue
        playModeCompleteBlock:(nullable DLUpdatOnPlayModeComplete)playModeCompleteBlock
        pauseModeCompleteBlock:(nullable DLUpdatOnPauseModeComplete)pauseModeCompleteBlock
{
    NSAssert(type != DLAVSnycUpdateProgressTypeNone, @"Must deliver an update type");
    NSAssert(!(playModeCompleteBlock != nil && pauseModeCompleteBlock != nil), @"Shoud be only one mode");
    [self freeBufferedFrames];
    NSTimeInterval position = 0.0;
    if (type == DLAVSnycUpdateProgressTypeRatio) {
        NSAssert(updateValue <= 1.0, @"Ratio Should not large than 1.0");
        position = updateValue * self.decoder.duration;
    } else if (type == DLAVSnycUpdateProgressTypeDelta) {
        position = updateValue + _moviePosition;
        NSAssert(position != MAXFLOAT, @"Delta value error");
    }
    
    position = MIN(self.decoder.duration - 1, MAX(0, position));
    
    dispatch_async(_dispatchQueue, ^{
        [self setDecoderPosition: position];
        
        if (playModeCompleteBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setMoviePositionFromDecoder];
                playModeCompleteBlock();
            });
        }
        if (pauseModeCompleteBlock) {
            [self decodeFrames];
            dispatch_async(dispatch_get_main_queue(), ^{
                pauseModeCompleteBlock();
                [self setMoviePositionFromDecoder];
                [self presentFrame];
                [self updateHUD];
            });
        }
    });
}

- (void)setupHardwareSamplingRate:(Float64)samplingRate numOutputChannels:(UInt32)numOutputChannels {
    self.decoder.hardwareSamplingRate = samplingRate;
    self.decoder.hardwareNumOutputChannels = numOutputChannels;
}

#pragma mark - DLAVSynchronizerProtocol's private

- (id<DLDecoderProtocol>)decoder {
    if (!_decoder) {
        _decoder = [DLDecoder decoderWithType:DLDecoderTypeBase];
    }
    return _decoder;
}

- (BOOL)OpenFileFinishedHandle:(NSError *)error {
    if (!error) {
        self.dispatchQueue  = dispatch_queue_create(kDecodeFrameSerialQuueue, DISPATCH_QUEUE_SERIAL);
        self.videoFrames = [NSMutableArray<DLVideoFrameProtocol> array];
        self.audioFrames = [NSMutableArray<DLAudioFrameProtocol> array];
        
        if (self.decoder.isNetwork) {
            self.minBufferedDuration = NETWORK_MIN_BUFFERED_DURATION;
            self.maxBufferedDuration = NETWORK_MAX_BUFFERED_DURATION;
        } else {
            self.minBufferedDuration = LOCAL_MIN_BUFFERED_DURATION;
            self.maxBufferedDuration = LOCAL_MAX_BUFFERED_DURATION;
        }
        if (!self.decoder.validVideo)   {
            self.minBufferedDuration *= 10.0; // increase for audio
        }
        return YES;
    }
    NSLog(@"Failed: %@", [error localizedDescription]);
    return NO;
}

- (BOOL) interruptDecoder   {
    return _interrupted;
}

// Decoder
- (void) asyncDecodeFrames  {
    if (_decoding)  {
        return;
    }
    __weak typeof(self) weakSelf = self;
    __weak DLDecoder *weakDecoder = self.decoder;
    const CGFloat duration = self.decoder.isNetwork ? .0f : 0.1f;
    self.decoding = YES;
    
    dispatch_async(_dispatchQueue, ^{
        {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf.running)    {
                return;
            }
        }
        
        BOOL good = YES;
        while (good) {
            good = NO;
            @autoreleasepool {
                __strong DLDecoder *decoder = weakDecoder;
                if (decoder && (decoder.validVideo || decoder.validAudio)) {
                    NSArray *frames = [decoder decodeFrames:duration];
                    if (frames.count) {
                        __strong typeof(weakSelf) strongSelf = weakSelf;
                        if (strongSelf) {
                            good = [strongSelf addFrames:frames];
                        }
                    }
                }
            }
        }
        
        {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) strongSelf.decoding = NO;
        }
    });
}

- (void) tick   {
    if (_buffered && ((_bufferedDuration > _minBufferedDuration) || self.decoder.isEOF)) {
        self.tickCorrectionTime = 0;
        [self willChangeValueForKey:@"buffered"];
        self.buffered = NO;
        [self didChangeValueForKey:@"buffered"];
    }
    
    NSTimeInterval interval = 0;
    if (!_buffered) {
        interval = [self presentFrame];
    }
    
    if (self.running) {
        const NSUInteger leftFrames =
        (self.decoder.validVideo ? _videoFrames.count : 0) +
        (self.decoder.validAudio ? _audioFrames.count : 0);
        
        if (0 == leftFrames) {
            if (self.decoder.isEOF) {
                [self pause];
                [self updateHUD];
                return;
            }
            if (_minBufferedDuration > 0 && !_buffered) {
                [self willChangeValueForKey:@"buffered"];
                self.buffered = YES;
                [self didChangeValueForKey:@"buffered"];
            }
        }
        if (!leftFrames ||  !(_bufferedDuration > _minBufferedDuration)) {
            [self asyncDecodeFrames];
        }
        NSTimeInterval correction = [self tickCorrection];
        NSTimeInterval time = MAX(interval + correction, 0.01);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self tick];
        });
    }
    if ((self.tickCounter++ % kUpdateHudOnVideoFrameFrequency) == 0) {
        [self updateHUD];
    }
}

- (void) updateHUD  {
    const CGFloat duration = self.decoder.duration;
    const CGFloat position = _moviePosition - self.decoder.startTime;
    
    if (self.fillVideoDataDelegate && [self.fillVideoDataDelegate respondsToSelector:@selector(updateHUD:position:)]) {
        [self.fillVideoDataDelegate updateHUD:duration position:position];
    }
}

- (BOOL)addFrames:(NSArray *)frames   {
    if (self.decoder.validVideo) {
        @synchronized(_videoFrames) {
            for (id<DLVideoFrameProtocol> frame in frames)
                if (frame.type == DLAVFrameTypeVideo) {
                    [_videoFrames addObject:frame];
                    self.bufferedDuration += frame.duration;
                }
        }
    }
    if (self.decoder.validAudio) {
        @synchronized(_audioFrames) {
            for (id<DLAudioFrameProtocol> frame in frames)
                if (frame.type == DLAVFrameTypeAudio) {
                    [_audioFrames addObject:frame];
                    if (!self.decoder.validVideo)
                        self.bufferedDuration += frame.duration;
                }
        }
    }
    return _running && _bufferedDuration < _maxBufferedDuration;
}

- (NSTimeInterval) presentFrame    {
    CGFloat interval = 0;
    
    if (self.decoder.validVideo) {
        id<DLVideoFrameProtocol> frame;
        @synchronized(_videoFrames) {
            if (_videoFrames.count > 0) {
                frame = _videoFrames[0];
                [_videoFrames removeObjectAtIndex:0];
                self.bufferedDuration -= frame.duration;
            }
        }
        if (frame)  {
            interval = [self presentVideoFrame:frame];
        }
    }
    
    return interval;
}

- (NSTimeInterval) tickCorrection  {
    if (_buffered)  {
        return 0;
    }
    
    const NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    
    if (!_tickCorrectionTime) {
        self.tickCorrectionTime = now;
        self.tickCorrectionPosition = _moviePosition;
        return 0;
    }
    NSTimeInterval dPosition = _moviePosition - _tickCorrectionPosition;
    NSTimeInterval dTime = now - _tickCorrectionTime;
    NSTimeInterval correction = dPosition - dTime;
    
    if (correction > kThresholdCorrectionTime || correction < -kThresholdCorrectionTime) {
        correction = 0;
        self.tickCorrectionTime = 0;
    }
    
    return correction;
}

- (void) freeBufferedFrames {
    @synchronized(_videoFrames) {
        [_videoFrames removeAllObjects];
    }
    @synchronized(_audioFrames) {
        [_audioFrames removeAllObjects];
        self.currentAudioFrame = nil;
    }
//    if (_subtitles) {
//        @synchronized(_subtitles) {
//            [_subtitles removeAllObjects];
//        }
//    }
    self.bufferedDuration = 0;
}

- (NSTimeInterval)presentVideoFrame: (id<DLVideoFrameProtocol>)frame {
    if (self.fillVideoDataDelegate && [self.fillVideoDataDelegate respondsToSelector:@selector(fillVideoData:)]) {
        [self.fillVideoDataDelegate fillVideoData:frame];
    }
    self.moviePosition = frame.position;
    return frame.duration;
}

- (BOOL)decodeFrames {
    NSArray *frames = nil;
    if (self.decoder.validVideo ||  self.decoder.validAudio) {
        frames = [self.decoder decodeFrames:0];
    }
    if (frames.count) {
        return [self addFrames: frames];
    }
    return NO;
}

- (void) setDecoderPosition: (CGFloat) position {
    self.decoder.position = position;
}
- (void) setMoviePositionFromDecoder    {
    self.moviePosition = self.decoder.position;
}

@end
