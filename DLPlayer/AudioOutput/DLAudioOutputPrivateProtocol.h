//
//  DLAudioOutputPrivateProtocol.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/21.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLAudioOutputPrivateProtocol_h
#define DLAudioOutputPrivateProtocol_h


@protocol DLAudioOutputPrivateProtocol <NSObject>

@property (nonatomic, assign) Float32                     outputVolume;
@property (nonatomic, assign) BOOL                        isOn; // flag play or pause

@property (nonatomic, assign) BOOL                        initialized;
@property (nonatomic, assign) BOOL                        activated;
@property (nonatomic, assign) float                       *outData;
@property (nonatomic, assign) AudioUnit                   audioUnit;
@property (nonatomic, assign) AudioStreamBasicDescription outputFormat;
@property (nonatomic, assign) BOOL              playAfterSessionEndInterruption;

- (BOOL)checkAudioRoute;
- (BOOL)setupAudio;
- (BOOL)checkSessionProperties;
- (BOOL)renderFrames:(UInt32)numFrames
              ioData:(AudioBufferList *)ioData;

@end

#define AUDIO_PROPERTIES_COMPILE_SETUP \
@synthesize audioRoute = _audioRoute;\
@synthesize numBytesPerSample = _numBytesPerSample;\
@synthesize numOutputChannels = _numOutputChannels;\
@synthesize outputVolume = _outputVolume;\
@synthesize playing = _playing;\
@synthesize samplingRate = _samplingRate;\
@synthesize fillDataBlock = _fillDataBlock;\
\
@synthesize activated = _activated;\
@synthesize audioUnit = _audioUnit;\
@synthesize initialized = _initialized;\
@synthesize outData = _outData;\
@synthesize outputFormat = _outputFormat;\
@synthesize playAfterSessionEndInterruption = _playAfterSessionEndInterruption;\
@synthesize isOn = _isOn;\


#endif /* DLAudioOutputPrivateProtocol_h */
