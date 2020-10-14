//
//  DLAVSynchronizerPrivateProtocol.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/21.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLAVSynchronizerPrivateProtocol_h
#define DLAVSynchronizerPrivateProtocol_h
#import "DLDecoderProtocol.h"

@class DLAVFrame;

#pragma mark - Property

@protocol DLSynchronizerPrivateProtocol <NSObject>
@property (nonatomic, strong) id<DLDecoderProtocol>      decoder;                   // 解码器

/* 解码器工作队列：解码、释放资源的工作，都放在这个队列 */
@property (nonatomic, strong) dispatch_queue_t           dispatchQueue;             // 解码工作队列

@property (nonatomic, strong) NSMutableArray<id<DLVideoFrameProtocol>>            *videoFrames;              // 视频帧缓冲队列
@property (nonatomic, strong) NSMutableArray<id<DLAudioFrameProtocol>>            *audioFrames;              // 音频帧缓冲队列

@property (nonatomic, copy)   NSData                    *currentAudioFrame;        // 当前音频帧(或叫“音频工作帧”，填充音频回调)
@property (nonatomic, assign) NSUInteger                 currentAudioFramePos;      // 音频拷贝指针（指示从当前音频帧什么位置开始拷贝数据）

@property (nonatomic, assign) NSTimeInterval             moviePosition;             // 当前播放器帧的pts：视频优先，音频次之
@property (nonatomic, assign) BOOL                       buffered;

@property (nonatomic, assign) NSTimeInterval             tickCorrectionTime;        // "滴答"参考时间(参考帧渲染时的系统时间)
@property (nonatomic, assign) NSTimeInterval             tickCorrectionPosition;    // “滴答”参考帧pts
@property (nonatomic, assign) NSUInteger                 tickCounter;               // “滴答”计数器(渲染了几帧)，3帧更新一次进度条

@property (nonatomic, assign) NSTimeInterval             bufferedDuration;          // 当前已缓冲时长
@property (nonatomic, assign) NSTimeInterval             minBufferedDuration;       // 预设的最小缓冲时长
@property (nonatomic, assign) NSTimeInterval             maxBufferedDuration;       // 预设的最大缓冲时长

@property (nonatomic, assign)   BOOL                    running;
@property (nonatomic, assign)   BOOL                    decoding;
@property (nonatomic, assign)   BOOL                    isParsing;
@property (nonatomic, assign)   NSUInteger              videoWidth;
@property (nonatomic, assign)   NSUInteger              videoHeight;
@property (nonatomic, assign)   DLVideoFrameFormat      videoFrameFormat;


#pragma mark - Methods

- (BOOL)OpenFileFinishedHandle:(NSError *)error;

- (BOOL)interruptDecoder;

- (void)asyncDecodeFrames;

- (void)tick;

- (void)updateHUD;

- (BOOL)addFrames:(NSArray *)frames;

- (NSTimeInterval)presentFrame;

// Correct the next video render time
- (NSTimeInterval)tickCorrection;

- (void)freeBufferedFrames;

- (NSTimeInterval)presentVideoFrame:(id<DLVideoFrameProtocol>)frame;

- (BOOL)decodeFrames;

- (void)setDecoderPosition:(CGFloat)position;

- (void)setMoviePositionFromDecoder;

@end

#define SYNC_PROPERTIES_COMPILEOPTIONS_SETUP \
@dynamic videoHeight;\
@dynamic videoWidth;\
@dynamic videoFrameFormat;\
@synthesize fillVideoDataDelegate = _fillVideoDataDelegate;\
@synthesize isParsing = _isParsing;\
@synthesize isEOF = _isEOF;\
@synthesize interrupted = _interrupted;\
\
@synthesize decoder = _decoder;\
@synthesize audioFrames = _audioFrames;\
@synthesize buffered = _buffered;\
@synthesize bufferedDuration = _bufferedDuration;\
@synthesize currentAudioFrame = _currentAudioFrame;\
@synthesize currentAudioFramePos = _currentAudioFramePos;\
@synthesize dispatchQueue = _dispatchQueue;\
@synthesize maxBufferedDuration = _maxBufferedDuration;\
@synthesize minBufferedDuration = _minBufferedDuration;\
@synthesize moviePosition = _moviePosition;\
@synthesize tickCorrectionPosition = _tickCorrectionPosition;\
@synthesize tickCorrectionTime = _tickCorrectionTime;\
@synthesize tickCounter = _tickCounter;\
@synthesize videoFrames = _videoFrames;\
@synthesize decoding = _decoding;\
@synthesize running = _running;\


#endif /* DLAVSynchronizerPrivateProtocol_h */
