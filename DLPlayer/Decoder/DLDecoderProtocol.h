//
//  DLDecoderProtocol.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLDecoderProtocol_h
#define DLDecoderProtocol_h
#import <CoreGraphics/CGBase.h>
#import "DLAVFrameProtocol.h"

typedef BOOL(^DLDecoderInterruptCallback)(void);
typedef void(^DLDecoderEOFCallback)(BOOL);

@protocol DLDecoderProtocol <NSObject>

@property (readonly, nonatomic, strong) NSString *path; // 多媒体文件地址
@property (readonly, nonatomic) BOOL isEOF;             // 是否解码到文件末尾标记
@property (readonly, nonatomic) NSTimeInterval duration;       // 多媒体文件总时长
@property (readonly, nonatomic) CGFloat fps;            // 解码帧率 ???
@property (readonly, nonatomic) CGFloat sampleRate;     // 采样率 ???
@property (readonly, nonatomic) NSUInteger frameWidth;  // 视频帧宽度
@property (readonly, nonatomic) NSUInteger frameHeight; // 视频帧高度
@property (readonly, nonatomic) NSUInteger audioStreamsCount;   // 音频流总数
@property (readonly, nonatomic) NSUInteger subtitleStreamsCount;    // 字幕流总数
@property (readonly, nonatomic) BOOL validVideo;        // 视频有效标记
@property (readonly, nonatomic) BOOL validAudio;        // 音频有效标记
@property (readonly, nonatomic) BOOL validSubtitles;    // 字幕有效标记
@property (readonly, nonatomic, strong) NSDictionary *info; //
@property (readonly, nonatomic, strong) NSString *videoStreamFormatName;   // 视频流格式名称
@property (readonly, nonatomic) BOOL isNetwork;         // 是否是解码网络文件
@property (readonly, nonatomic) NSTimeInterval startTime;      // 文件开始时间

@property (readwrite, nonatomic) NSInteger selectedSubtitleStream;   // 选中解码哪一路字幕流
@property (readwrite, nonatomic) NSInteger selectedAudioStream;  // 选中解码哪一路音频流
@property (readwrite, nonatomic) NSTimeInterval position;       // 当前解码帧的position

@property (readwrite, nonatomic) Float64            hardwareSamplingRate;          // 硬件音频采样率
@property (readwrite, nonatomic) UInt32             hardwareNumOutputChannels;

@property (readwrite, nonatomic) BOOL disableDeinterlacing; // ???
// 解码中断回调
@property (readwrite, nonatomic, copy) DLDecoderInterruptCallback interruptCallback;
// 播放结束回调
@property (readwrite, nonatomic, copy) DLDecoderEOFCallback       eofCallback;

// 中断解码函数入口
- (BOOL)interruptDecoder;

// 打开文件流入口函数
- (BOOL)openFile:(NSString *)path
           error:(NSError **)perror;

// 关闭(释放)文件资源入口
-(void)closeFile;

// 设置视频帧格式
- (BOOL)setupVideoFrameFormat:(DLVideoFrameFormat)format;
- (DLVideoFrameFormat)getFrameFormat;

// 按最小时长限制，开始解码
- (NSArray *)decodeFrames:(NSTimeInterval)minDuration;

@end

#define DECODER_PROPERTIES_COMPILEOPTIONS_SETUP \
\
@dynamic duration;\
@dynamic frameWidth;\
@dynamic frameHeight;\
@dynamic sampleRate;\
@dynamic audioStreamsCount;\
@dynamic subtitleStreamsCount;\
@dynamic selectedAudioStream;\
@dynamic selectedSubtitleStream;\
@dynamic validAudio;\
@dynamic validVideo;\
@dynamic validSubtitles;\
@dynamic videoStreamFormatName;\
@dynamic startTime;\
\
@synthesize hardwareSamplingRate = _hardwareSamplingRate;\
@synthesize hardwareNumOutputChannels = _hardwareNumOutputChannels;


#endif /* DLDecoderProtocol_h */
