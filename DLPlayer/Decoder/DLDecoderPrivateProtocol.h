//
//  DLDecoderPrivateProtocol.h
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DlDecoderPrivateProtocol_h
#define DlDecoderPrivateProtocol_h
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <Accelerate/Accelerate.h>
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/pixdesc.h"
#include "libavdevice/avdevice.h"
#import  "DLAVFrameProtocol.h"
#import "DlDecoderErrorDefines.h"


@protocol DLDecoderPrivateProtocol <NSObject>

@property (nonatomic, assign) AVFormatContext     *formatCtx;            // 多媒体文件格式上下文
@property (nonatomic, assign) AVCodecContext      *videoCodecCtx;        // 视频 解码上下文
@property (nonatomic, assign) AVCodecContext      *audioCodecCtx;        // 音频 解码上下文
@property (nonatomic, assign) AVCodecContext      *subtitleCodecCtx;     // 字幕 解码上下文
@property (nonatomic, assign) AVFrame             *videoFrame;           // 当前 yuv视频帧
@property (nonatomic, assign) AVFrame             *audioFrame;           // 当前 音频帧
@property (nonatomic, assign) NSInteger           videoStream;           // 当前 视频流
@property (nonatomic, assign) NSInteger           audioStream;           // 当前 音频流
@property (nonatomic, assign) NSInteger           subtitleStream;        // 当前 字幕流
@property (nonatomic, assign) AVPicture           picture;               // 当前 rgb视频帧
@property (nonatomic, assign) BOOL                pictureValid;          // 图像有效标记
@property (nonatomic, assign) struct SwsContext   *swsContext;           // 视频裁剪上下文
@property (nonatomic, assign) NSTimeInterval      videoTimeBase;         // 视频时间基数
@property (nonatomic, assign) NSTimeInterval      audioTimeBase;         // 音频时间基数
@property (nonatomic, strong) NSArray             *videoStreams;         // 视频流数组
@property (nonatomic, strong) NSArray             *audioStreams;         // 音频流数组
@property (nonatomic, strong) NSArray             *subtitleStreams;      // 字幕流数组
@property (nonatomic, assign) SwrContext          *swrContext;           // 音频重采样上下文
@property (nonatomic, assign) void                *swrBuffer;            // 音频重采样缓冲指针
@property (nonatomic, assign) NSUInteger          swrBufferSize;         // 音频重采样缓冲尺寸
@property (nonatomic, assign) DLVideoFrameFormat  videoFrameFormat;      // 视频帧格式(YUV/RGB)
@property (nonatomic, assign) NSUInteger          artworkStream;         //
@property (nonatomic, assign) NSInteger           subtitleASSEvents;


- (DLDecoderError)openInput:(NSString *)path;

- (DLDecoderError)openVideoStream;

- (DLDecoderError)openVideoStream:(NSInteger)videoStream;

- (DLDecoderError)openAudioStream;

- (DLDecoderError)openAudioStream:(NSInteger)audioStream;

- (DLDecoderError)openSubtitleStream:(NSInteger)subtitleStream;

- (void)closeVideoStream;

- (void)closeAudioStream;

- (void)closeSubtitleStream;

- (void)closeScaler;

- (BOOL)setupScaler;

- (id<DLVideoFrameProtocol>)handleVideoFrame;

- (id<DLAudioFrameProtocol>)handleAudioFrame;

- (id<DLSubtitleFrameProtocol>)handleSubtitle:(AVSubtitle *)pSubtitle;

@end

#define DECODER_PRIVATE_PROPERTIES_COMPILEOPTIONS_SETUP \
@synthesize position = _position;\
@synthesize info = _info;\
@synthesize artworkStream = _artworkStream;\
@synthesize audioCodecCtx = _audioCodecCtx;\
@synthesize audioFrame = _audioFrame;\
@synthesize audioStream = _audioStream;\
@synthesize audioStreams = _audioStreams;\
@synthesize audioTimeBase = _audioTimeBase;\
@synthesize disableDeinterlacing = _disableDeinterlacing;\
@synthesize formatCtx = _formatCtx;\
@synthesize fps = _fps;\
@synthesize interruptCallback = _interruptCallback;\
@synthesize eofCallback = _eofCallback;\
@synthesize isEOF = _isEOF;\
@synthesize isNetwork = _isNetwork;\
@synthesize path = _path;\
@synthesize picture = _picture;\
@synthesize pictureValid = _pictureValid;\
@synthesize subtitleASSEvents = _subtitleASSEvents;\
@synthesize subtitleCodecCtx = _subtitleCodecCtx;\
@synthesize subtitleStream = _subtitleStream;\
@synthesize subtitleStreams = _subtitleStreams;\
@synthesize swrBuffer = _swrBuffer;\
@synthesize swrBufferSize = _swrBufferSize;\
@synthesize swrContext = _swrContext;\
@synthesize swsContext = _swsContext;\
@synthesize videoCodecCtx = _videoCodecCtx;\
@synthesize videoFrame = _videoFrame;\
@synthesize videoFrameFormat = _videoFrameFormat;\
@synthesize videoStream = _videoStream;\
@synthesize videoStreams = _videoStreams;\
@synthesize videoTimeBase = _videoTimeBase;\

#endif /* DlDecoderPrivateProtocol_h */
