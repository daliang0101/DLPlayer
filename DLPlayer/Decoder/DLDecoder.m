//
//  DLDecoder.m
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLDecoder.h"
#import "DLDecoderBase.h"

@interface DLDecoder ()
@property (nonatomic, strong) id<DLDecoderProtocol> defaultDecoder;
@end

@implementation DLDecoder

- (instancetype)init {
    if (self = [super init]) {
        [self setupDefaultDecoder];
    }
    return self;
}

- (void)setupDefaultDecoder {
    self.defaultDecoder = [[DLDecoderBase alloc] init];
}

+ (id<DLDecoderProtocol>)decoderWithType:(DLDecoderType)type {
    switch (type) {
        case DLDecoderTypeBase:
            return [[DLDecoderBase alloc] init];
            break;
        default:
            return [[DLDecoderBase alloc] init];
            break;
    }
    return nil;
}

+ (instancetype)instanceDecoderWithType:(DLDecoderType)type {
    return [self decoderWithType:type];
}

@dynamic audioStreamsCount;
- (NSUInteger)audioStreamsCount {
    return _defaultDecoder.audioStreamsCount;
}
@dynamic disableDeinterlacing;
- (BOOL)disableDeinterlacing {
    return _defaultDecoder.disableDeinterlacing;
}
- (void)setDisableDeinterlacing:(BOOL)disableDeinterlacing {
    _defaultDecoder.disableDeinterlacing = disableDeinterlacing;
}
@dynamic duration;
- (NSTimeInterval)duration {
    return _defaultDecoder.duration;
}

@dynamic fps;
- (CGFloat)fps {
    return _defaultDecoder.fps;
}

@dynamic frameHeight;
- (NSUInteger)frameWidth {
    return _defaultDecoder.frameWidth;
}

@dynamic frameWidth;
- (NSUInteger)frameHeight {
    return _defaultDecoder.frameHeight;
}

@dynamic hardwareNumOutputChannels;
- (UInt32)hardwareNumOutputChannels {
    return _defaultDecoder.hardwareNumOutputChannels;
}
- (void)setHardwareNumOutputChannels:(UInt32)hardwareNumOutputChannels {
    _defaultDecoder.hardwareNumOutputChannels = hardwareNumOutputChannels;
}

@dynamic hardwareSamplingRate;
- (Float64)hardwareSamplingRate {
    return _defaultDecoder.hardwareSamplingRate;
}
- (void)setHardwareSamplingRate:(Float64)hardwareSamplingRate {
    _defaultDecoder.hardwareSamplingRate = hardwareSamplingRate;
}

@dynamic info;
- (NSDictionary *)info {
    return _defaultDecoder.info;
}

@dynamic interruptCallback;
- (DLDecoderInterruptCallback)interruptCallback {
    return _defaultDecoder.interruptCallback;
}
- (void)setInterruptCallback:(DLDecoderInterruptCallback)interruptCallback {
    _defaultDecoder.interruptCallback = interruptCallback;
}

@dynamic isEOF;
- (BOOL)isEOF {
    return _defaultDecoder.isEOF;
}

@dynamic isNetwork;
- (BOOL)isNetwork {
    return _defaultDecoder.isNetwork;
}

@dynamic path;
- (NSString *)path {
    return _defaultDecoder.path;
}

@dynamic position;
- (NSTimeInterval)position {
    return _defaultDecoder.position;
}
- (void)setPosition:(NSTimeInterval)position {
    _defaultDecoder.position = position;
}

@dynamic sampleRate;
- (CGFloat)sampleRate {
    return _defaultDecoder.sampleRate;
}

@dynamic selectedAudioStream;
- (NSInteger)selectedAudioStream {
    return _defaultDecoder.selectedAudioStream;
}
- (void)setSelectedAudioStream:(NSInteger)selectedAudioStream {
    _defaultDecoder.selectedAudioStream = selectedAudioStream;
}

@dynamic selectedSubtitleStream;
- (NSInteger)selectedSubtitleStream {
    return _defaultDecoder.selectedSubtitleStream;
}
- (void)setSelectedSubtitleStream:(NSInteger)selectedSubtitleStream {
    _defaultDecoder.selectedSubtitleStream = selectedSubtitleStream;
}

@dynamic startTime;
- (NSTimeInterval)startTime {
    return _defaultDecoder.startTime;
}

@dynamic subtitleStreamsCount;
- (NSUInteger)subtitleStreamsCount {
    return _defaultDecoder.subtitleStreamsCount;
}

@dynamic validAudio;
- (BOOL)validAudio {
    return _defaultDecoder.validAudio;
}

@dynamic validSubtitles;
- (BOOL)validSubtitles {
    return _defaultDecoder.validSubtitles;
}

@dynamic validVideo;
- (BOOL)validVideo {
    return _defaultDecoder.validVideo;
}

@dynamic videoStreamFormatName;
- (NSString *)videoStreamFormatName {
    return _defaultDecoder.videoStreamFormatName;
}

@dynamic eofCallback;
- (DLDecoderEOFCallback)eofCallback {
    return _defaultDecoder.eofCallback;
}

- (void)closeFile {
    [_defaultDecoder closeFile];
}

- (NSArray *)decodeFrames:(NSTimeInterval)minDuration {
    return [_defaultDecoder decodeFrames:minDuration];
}

- (DLVideoFrameFormat)getFrameFormat {
    return [_defaultDecoder getFrameFormat];
}

- (BOOL)interruptDecoder {
    return _defaultDecoder.interruptDecoder;
}

- (BOOL)openFile:(NSString *)path error:(NSError *__autoreleasing *)perror {
    return [_defaultDecoder openFile:path error:perror];
}

- (BOOL)setupVideoFrameFormat:(DLVideoFrameFormat)format {
    return [_defaultDecoder setupVideoFrameFormat:format];
}

@end
