//
//  DLPlayerControllerPrivateProtocol.h
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/21.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLPlayerControllerPrivateProtocol_h
#define DLPlayerControllerPrivateProtocol_h
#import "DLAudioOutput.h"
#import "DLVideoOutput.h"
#import "DLAVSynchronizer.h"


typedef NS_ENUM(NSUInteger, DLPlayerState) {
    DLPlayerStateNone            = 1 << 0,
    DLPlayerStateStoped          = 1 << 1,
    DLPlayerStatePreparing       = 1 << 2,
    DLPlayerStatePrepared        = 1 << 3,
    DLPlayerStatePaused          = 1 << 4,
    DLPlayerStateLoading         = 1 << 5,
    DLPlayerStatePlaying         = 1 << 6,
    DLPlayerStateEOF             = 1 << 7,
};

@protocol DLPlayerControllerPrivateProtocol <DLAVSynchronizerDelegate>

@property (nonatomic,   strong)     id<DLAudioOutputProtocol>       audioOutput;
@property (nonatomic,   strong)     id<DLVideoOutputProtocol>       videoOutput;
@property (nonatomic,   strong)     id<DLAVSynchronizerProtocol>    avSynchronizer;

@property (nonatomic, readonly)     DLPlayerState                   playerState;

@property (nonatomic,  copy  )      NSString                        *path;

@property (nonatomic, assign)       BOOL                             playModeBeforeResignActive;
@property (nonatomic, assign)       BOOL                             disableUpdateHUD;

/**
 * Thresholds
 */
@property (nonatomic, assign)       BOOL                             lastPlayOrPauseState;
@property (nonatomic, assign)       BOOL                             timeToRunPlayOrPause;
@property (nonatomic, assign)       BOOL                             timeToRunSeekInterval;

@property (nonatomic, strong)       dispatch_semaphore_t             preparedToPlay_semaphore;

- (void)setupAVSynchronizer;
- (void)setupAudioOutput;
- (void)setupVideoOutput;

- (void)fillAudioData:(float *)outData
            numFrames:(UInt32 )numFrames
          numChannels:(UInt32 )numChannels;

- (void)realPlay;

- (void)registerNotifications;
- (void)removeNotifications;
- (void)applicationWillResignActive:(NSNotification *)notify;
- (void)applicationDidBecomeActive:(NSNotification *)notify;

@end

#define PLAYERVC_PROPERTIES_COMPILEOPTIONS_SETUP \
@dynamic playerView;\
@synthesize audioOutput                     = _audioOutput;\
@synthesize videoOutput                     = _videoOutput;\
@synthesize avSynchronizer                  = _avSynchronizer;\
@synthesize path                            = _path;\
@synthesize playerState                     = _playerState;\
@synthesize playModeBeforeResignActive      = _playModeBeforeResignActive;\
@synthesize preparedToPlay_semaphore        = _preparedToPlay_semaphore;\
@synthesize delegate                        = _delegate;\
@synthesize disableUpdateHUD                = _disableUpdateHUD;\
@synthesize lastPlayOrPauseState            = _lastPlayOrPauseState;\
@synthesize timeToRunPlayOrPause            = _timeToRunPlayOrPause;\
@synthesize timeToRunSeekInterval           = _timeToRunSeekInterval;\
@synthesize mute                            = _mute;\


#endif /* DLPlayerControllerPrivateProtocol_h */
