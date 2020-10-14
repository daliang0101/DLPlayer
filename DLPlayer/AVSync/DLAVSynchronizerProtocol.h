//
//  DLAVSynchronizerProtocol.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLAVSynchronizerProtocol_h
#define DLAVSynchronizerProtocol_h
#import "DLAVFrameProtocol.h"

typedef NS_ENUM(NSUInteger, DLAVSnycUpdateProgressType) {
    DLAVSnycUpdateProgressTypeNone,
    DLAVSnycUpdateProgressTypeRatio,
    DLAVSnycUpdateProgressTypeDelta,
};
typedef void(^DLUpdatOnPlayModeComplete)(void);
typedef void(^DLUpdatOnPauseModeComplete)(void);

@class DLAVFrame;
@protocol DLAVSynchronizerDelegate <NSObject>
- (void)fillVideoData:(id<DLVideoFrameProtocol>_Nullable)frame;
- (void)updateHUD:(NSTimeInterval)duration position:(NSTimeInterval)position;
@end

@protocol DLAVSynchronizerProtocol <NSObject>
@property (nonatomic, weak) id<DLAVSynchronizerDelegate> _Nullable fillVideoDataDelegate;

@property (nonatomic, assign, readonly)   BOOL                           isParsing;
@property (nonatomic, assign, readonly)   BOOL                           isEOF;
@property (nonatomic, assign, readonly)   NSUInteger                     videoWidth;
@property (nonatomic, assign, readonly)   NSUInteger                     videoHeight;
@property (nonatomic, assign, readonly)   DLVideoFrameFormat             videoFrameFormat;

/**
 * Must call this before 'start:'.
 * For audio resample, use the params to setup decoder.
 */
- (void)setupHardwareSamplingRate:(Float64)samplingRate
              numOutputChannels:(UInt32)numOutputChannels;
- (BOOL)start:(NSString *_Nullable)path;
- (void)run;
- (void)pause;
- (void)stop;

- (void)fillAudioData:(float *_Nullable)outData
            numFrames:(UInt32 )numFrames
          numChannels:(UInt32 )numChannels;

- (BOOL)handleMemoryWarningOnPlayMode:(BOOL)isPlay;

@optional
@property (nonatomic, assign)             BOOL                           interrupted;

- (void)updateOnType:(DLAVSnycUpdateProgressType)type
        updateValue:(float)updateValue
        playModeCompleteBlock:(nullable DLUpdatOnPlayModeComplete)playModeCompleteBlock
        pauseModeCompleteBlock:(nullable DLUpdatOnPauseModeComplete)pauseModeCompleteBlock;
@end

#endif /* DLAVSynchronizerProtocol_h */
