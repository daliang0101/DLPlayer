//
//  DLAudioOutputProtocol.h
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLAudioOutputProtocol_h
#define DLAudioOutputProtocol_h

typedef void (^DLAudioOutputFillDataBlock)(float *data, UInt32 numFrames, UInt32 numChannels);

@protocol DLAudioOutputProtocol <NSObject>

@property (nonatomic, readonly, assign) UInt32                      numOutputChannels;
@property (nonatomic, readonly, assign) Float64                     samplingRate;
@property (nonatomic, readonly, assign) UInt32                      numBytesPerSample;
@property (nonatomic, readonly, assign) Float32                     outputVolume;
@property (nonatomic, readonly, assign) BOOL                        playing;
@property (nonatomic, readonly, copy)   NSString                    *audioRoute;

@property (nonatomic, copy)             DLAudioOutputFillDataBlock  fillDataBlock;

- (BOOL)activateAudioSession;
- (void)deactivateAudioSession;
- (BOOL)play;
- (void)pause;
- (void)stop;

@end

#endif /* DLAudioOutputProtocol_h */
