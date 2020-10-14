//
//  DLAVSynchronizer.m
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLAVSynchronizer.h"
#import "DLAVSynchronizerBase.h"

@interface DLAVSynchronizer ()
@property (nonatomic, strong) id<DLAVSynchronizerProtocol> defaultAVSynchronizer;
@end

@implementation DLAVSynchronizer

@dynamic isParsing;
@dynamic videoHeight;
@dynamic videoWidth;
@dynamic interrupted;
@dynamic videoFrameFormat;
@synthesize fillVideoDataDelegate;
@synthesize isEOF;

- (BOOL)isParsing {
    return _defaultAVSynchronizer.isParsing;
}
- (NSUInteger)videoWidth {
    return _defaultAVSynchronizer.videoWidth;
}
- (NSUInteger)videoHeight {
    return _defaultAVSynchronizer.videoHeight;
}
- (BOOL)interrupted {
    return _defaultAVSynchronizer.interrupted;
}
- (void)setInterrupted:(BOOL)interrupted {
    _defaultAVSynchronizer.interrupted = interrupted;
}
- (DLVideoFrameFormat)videoFrameFormat {
    return _defaultAVSynchronizer.videoFrameFormat;
}

- (instancetype)init {
    if (self = [super init]) {
        _defaultAVSynchronizer = [[DLAVSynchronizerBase alloc] init];
    }
    return self;
}

+ (instancetype)avSynchronizerWithType:(DLAVSynchronizerType)type {
    return (DLAVSynchronizer *)[self synchronizerWithType:type];
}

+ (id<DLAVSynchronizerProtocol>)synchronizerWithType:(DLAVSynchronizerType)type {
    switch (type) {
        case DLAVSynchronizerTypeBase:
            return [[DLAVSynchronizerBase alloc] init];
            break;
            
        default:
            return [[DLAVSynchronizerBase alloc] init];
            break;
    }
    return nil;
}

- (void)fillAudioData:(float * _Nullable)outData numFrames:(UInt32)numFrames numChannels:(UInt32)numChannels {
    [_defaultAVSynchronizer fillAudioData:outData numFrames:numFrames numChannels:numFrames];
}

- (BOOL)handleMemoryWarningOnPlayMode:(BOOL)isPlay {
    return [_defaultAVSynchronizer handleMemoryWarningOnPlayMode:isPlay];
}

- (void)pause {
    [_defaultAVSynchronizer pause];
}

- (void)run {
    [_defaultAVSynchronizer run];
}

- (BOOL)start:(NSString * _Nullable)path {
    return [_defaultAVSynchronizer start:path];
}

- (void)stop {
    [_defaultAVSynchronizer stop];
}

- (void)updateOnType:(DLAVSnycUpdateProgressType)type updateValue:(float)updateValue playModeCompleteBlock:(DLUpdatOnPlayModeComplete)playModeCompleteBlock pauseModeCompleteBlock:(DLUpdatOnPauseModeComplete)pauseModeCompleteBlock
{
    [_defaultAVSynchronizer updateOnType:type updateValue:updateValue playModeCompleteBlock:playModeCompleteBlock pauseModeCompleteBlock:pauseModeCompleteBlock];
}

- (void)setupHardwareSamplingRate:(Float64)samplingRate numOutputChannels:(UInt32)numOutputChannels {
    [_defaultAVSynchronizer setupHardwareSamplingRate:samplingRate numOutputChannels:numOutputChannels];
}

@end
