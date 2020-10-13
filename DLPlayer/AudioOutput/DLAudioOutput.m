//
//  DLAudioOutput.m
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLAudioOutput.h"
#import "DLAudioOutputAudioUnit.h"

@interface DLAudioOutput ()
@property (nonatomic, strong) id<DLAudioOutputProtocol> defaultAudioOutput;
@end

static id<DLAudioOutputProtocol> sharedAudioUnitObj;

@implementation DLAudioOutput

@dynamic audioRoute;
@dynamic fillDataBlock;
@dynamic numBytesPerSample;
@dynamic numOutputChannels;
@dynamic outputVolume;
@dynamic playing;
@dynamic samplingRate;

- (instancetype)init {
    if (self = [super init]) {
        [self setupDefaultOutput];
    }
    return self;
}

- (void)setupDefaultOutput {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAudioUnitObj = [[DLAudioOutputAudioUnit alloc] init];
    });
    _defaultAudioOutput = (DLAudioOutput *)sharedAudioUnitObj;
}

+ (id<DLAudioOutputProtocol>)outputWithType:(DLAudioOutputType)type {
    switch (type) {
        case DLAudioOutputTypeAudioUnit:
            return [self sharedAudioUnit];
            break;
            
        default:
            return [self sharedAudioUnit];
            break;
    }
    return nil;
}

+ (instancetype)audioOutputWithType:(DLAudioOutputType)type {
    return [self outputWithType:type];
}

+ (id<DLAudioOutputProtocol>)sharedAudioUnit
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAudioUnitObj = [[DLAudioOutputAudioUnit alloc] init];
    });
    return sharedAudioUnitObj;
}

- (NSString *)audioRoute {
    return _defaultAudioOutput.audioRoute;
}
- (UInt32)numOutputChannels {
    return _defaultAudioOutput.numOutputChannels;
}
- (Float64)samplingRate {
    return _defaultAudioOutput.samplingRate;
}
- (UInt32)numBytesPerSample {
    return _defaultAudioOutput.numBytesPerSample;
}
- (Float32)outputVolume {
    return _defaultAudioOutput.outputVolume;
}
- (BOOL)playing {
    return _defaultAudioOutput.playing;
}
- (DLAudioOutputFillDataBlock)fillDataBlock {
    return _defaultAudioOutput.fillDataBlock;
}
- (void)setFillDataBlock:(DLAudioOutputFillDataBlock)fillDataBlock {
    _defaultAudioOutput.fillDataBlock = fillDataBlock;
}

- (BOOL)activateAudioSession {
    return [_defaultAudioOutput activateAudioSession];
}

- (void)deactivateAudioSession {
    [_defaultAudioOutput deactivateAudioSession];
}

- (void)pause {
    [_defaultAudioOutput pause];
}

- (BOOL)play {
    return [_defaultAudioOutput play];
}

- (void)stop {
    [_defaultAudioOutput stop];
}

@end
