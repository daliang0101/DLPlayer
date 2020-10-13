//
//  DLPlayerControllerBase.m
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLPlayerControllerBase.h"
#import "DLPlayerControllerPrivateProtocol.h"
#import <UIKit/UIApplication.h>

@interface DLPlayerControllerBase () <DLPlayerControllerPrivateProtocol>

@end

static NSTimeInterval kDLResponseToPlayOrPauseActionThresholdTime       = 0.1;
static NSTimeInterval kDLResponseToRewindOrForwardActionThresholdTime   = 0.2;

@implementation DLPlayerControllerBase

PLAYERVC_PROPERTIES_COMPILEOPTIONS_SETUP

- (instancetype)init  {
    if (self = [super init]) {
        _playerState = DLPlayerStateNone;
        _timeToRunPlayOrPause = YES;
        _timeToRunSeekInterval = YES;
        _preparedToPlay_semaphore = dispatch_semaphore_create(0);
        [self registerNotifications];
        [self setupAudioOutput];
        [self setupAVSynchronizer];
        [self setupVideoOutput];
    }
    return self;
}

- (void)dealloc {
    [self removeNotifications];
}

#pragma mark -
#pragma mark -
#pragma mark -- DLPlayerControllerProtocol -----
#pragma mark -

- (UIView *)playerView {
    return self.videoOutput.glView;
}

- (void)playPath:(NSString *)path {
    if (![_path isEqualToString:path]) {
        self.path = path;
        [self prepareToPlay];
        [self play];
    }
}

- (void)prepareToPlayPath:(NSString *)path {
    if (![_path isEqualToString:path]) {
        self.path = path;
        [self prepareToPlay];
    }
}

- (void)prepareToPlay {
    if (_playerState & (DLPlayerStateNone | DLPlayerStateStoped)) {
        
        [self stop];
        
        _playerState &= ~DLPlayerStateNone;
        _playerState &= ~DLPlayerStateStoped;
        _playerState |= DLPlayerStatePreparing;
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            if ([self.avSynchronizer start:self.path]) {
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    
                    [self setupVideoOutput];
                    
                    self->_playerState &= ~DLPlayerStatePreparing;
                    self->_playerState |= DLPlayerStatePrepared;
                });
                
                dispatch_semaphore_signal(self.preparedToPlay_semaphore);
                
            } else {
                self->_playerState = DLPlayerStateNone;
                NSLog(@"Prepare file resource failed---!!!");
            }
        });
    }
}

- (void)seekInterval:(NSTimeInterval)interval {
    if (_timeToRunSeekInterval) {
        self.timeToRunSeekInterval = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kDLResponseToRewindOrForwardActionThresholdTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.disableUpdateHUD = YES;
            [self updateProgrestype:DLAVSnycUpdateProgressTypeDelta updateValue:interval];
            self.timeToRunSeekInterval = YES;
        });
    }
}

- (void)seekToRatio:(float)ratio {
    self.disableUpdateHUD = YES;
    [self updateProgrestype:DLAVSnycUpdateProgressTypeRatio updateValue:ratio];
}

- (void)pause {
    if (_playerState & (DLPlayerStatePaused | DLPlayerStateNone | DLPlayerStateStoped)) {
        return;
    }
    _playerState |= DLPlayerStatePaused;
    _playerState &= ~DLPlayerStatePlaying;
    [self.audioOutput pause];
    [self.videoOutput pause];
    [_avSynchronizer pause];
}

- (void)play {
    self.disableUpdateHUD = NO;
    
    if (_playerState & DLPlayerStatePlaying) {
        return;
    }
    if (_playerState & (DLPlayerStateStoped | DLPlayerStateNone)) {
        [self prepareToPlay];
        [self play];
        return;
    }
    
    _playerState |= DLPlayerStatePlaying;
    _playerState &= ~DLPlayerStatePaused;
    
    if (_playerState & DLPlayerStateEOF) {
        // seek to start position
        _playerState &= ~DLPlayerStateEOF;
        _playerState |= DLPlayerStatePrepared;
        [self seekToRatio:-1.0];
        return;
    }
    
    if (_playerState & DLPlayerStatePreparing) {
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            dispatch_semaphore_wait(self.preparedToPlay_semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
            
            if (self->_playerState & (DLPlayerStatePrepared | DLPlayerStatePlaying)) {
                self->_playerState &= ~DLPlayerStatePreparing;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self realPlay];
                });
            }
        });
    } else if (_playerState & DLPlayerStatePrepared) {
        [self realPlay];
    }
}
- (void)playOrPause:(BOOL)play {
    
    self.lastPlayOrPauseState = play;
    
    if (_timeToRunPlayOrPause) {
        self.timeToRunPlayOrPause = NO;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kDLResponseToPlayOrPauseActionThresholdTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.lastPlayOrPauseState) {
                [self play];
            } else {
                [self pause];
            }
            self.timeToRunPlayOrPause = YES;
        });
    }
}
- (void)realPlay  {
    _playerState |= DLPlayerStatePlaying;
    _playerState &= ~DLPlayerStatePaused;
    [self.audioOutput play];
    [self.videoOutput play];
    [_avSynchronizer run];
}

- (void)stop {
    if (!(_playerState & (DLPlayerStateStoped | DLPlayerStateNone))) {
        _playerState = DLPlayerStateStoped;
        self.disableUpdateHUD = NO;
        [self.audioOutput stop];
        [self.videoOutput stop];
        [self.avSynchronizer stop];
        [self.videoOutput render:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.delegate onDLPProgressDidChange:0 position:0];
        });
    }
}

#pragma mark -
#pragma mark -
#pragma mark -- DLPlayerControllerPrivateProtocol -----
#pragma mark -

- (id<DLAudioOutputProtocol>)audioOutput {
    if (!_audioOutput) {
        _audioOutput = [DLAudioOutput outputWithType:DLAudioOutputTypeAudioUnit];
        [_audioOutput activateAudioSession];
    }
    return _audioOutput;
}
- (id<DLVideoOutputProtocol>)videoOutput {
    if (!_videoOutput) {
        _videoOutput = [DLVideoOutput videoOutputWithType:DLVideoOutputTypeBase];
    }
    return _videoOutput;
}
- (id<DLAVSynchronizerProtocol>)avSynchronizer {
    if (!_avSynchronizer) {
        DLAVSynchronizer *sync = [DLAVSynchronizer synchronizerWithType:DLAVSynchronizerTypeBase];
        sync.fillVideoDataDelegate = self;

        [sync addObserver:self forKeyPath:@"isParsing" options:(
                                                                NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:(__bridge void * _Nullable)([self class])];

        [sync addObserver:self forKeyPath:@"buffered" options:(
                                                               NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:(__bridge void * _Nullable)([self class])];

        [sync addObserver:self forKeyPath:@"isEOF" options:(
                                                               NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:(__bridge void * _Nullable)([self class])];
        
        _avSynchronizer = sync;
    }
    return _avSynchronizer;
}

- (void)fillAudioData:(float *)outData
            numFrames:(UInt32 )numFrames
          numChannels:(UInt32 )numChannels
{
    [self.avSynchronizer fillAudioData:outData numFrames:numFrames numChannels:numChannels];
}

- (void)setupAVSynchronizer {
    [self.avSynchronizer setupHardwareSamplingRate:self.audioOutput.samplingRate numOutputChannels:self.audioOutput.numOutputChannels];
}

- (void)setupAudioOutput {
    __weak typeof(self) weakSelf = self;
    self.audioOutput.fillDataBlock = ^(float *outData, UInt32 numFrames, UInt32 numChannels) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf fillAudioData:outData numFrames:numFrames numChannels:numChannels];
    };
}

- (void)setupVideoOutput {
     [self.videoOutput setupVideoFormat:self.avSynchronizer.videoFrameFormat videoSize:CGSizeMake(self.avSynchronizer.videoWidth, self.avSynchronizer.videoHeight)];
}

- (void)handleReceiveMemoryWarning {
    if (_playerState & DLPlayerStatePlaying) {
        [self pause];
        if ([_avSynchronizer handleMemoryWarningOnPlayMode:YES]) {
            [self play];
        }
    } else {
        [_avSynchronizer handleMemoryWarningOnPlayMode:NO];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notify {
    if (_playModeBeforeResignActive) {
        [self play];
    }
}

- (void)applicationWillResignActive:(NSNotification *)notify {
    self.playModeBeforeResignActive = _playerState & DLPlayerStatePlaying;
    [self pause];
}

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:[UIApplication sharedApplication]];
}

- (void)removeNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
}

- (void)fillVideoData:(id<DLVideoFrameProtocol> _Nullable)frame {
    [self.videoOutput render:frame];
}

- (void)updateHUD:(NSTimeInterval)duration position:(NSTimeInterval)position {
    if (!_disableUpdateHUD) {
        [self.delegate onDLPProgressDidChange:duration position:position];
    }
}

- (void)updateProgrestype:(DLAVSnycUpdateProgressType)type updateValue:(float)updateValue {
    
    __weak typeof(self) weakSelf = self;
    DLUpdatOnPlayModeComplete playModeComplete = nil;
    DLUpdatOnPauseModeComplete pauseModeComplete = nil;
    
    if (_playerState & DLPlayerStatePlaying) {
        playModeComplete = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.disableUpdateHUD = NO;
            [strongSelf play];
        };
    } else if (_playerState & (DLPlayerStatePaused | DLPlayerStateLoading | DLPlayerStatePrepared)) {
        pauseModeComplete = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.disableUpdateHUD = NO;
        };
    } else if (_playerState & (DLPlayerStateStoped | DLPlayerStateNone)) {
//        [self prepareToPlay];
//        [self play];
//        return;
    }
    
    [self pause];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self->_avSynchronizer updateOnType:type updateValue:updateValue playModeCompleteBlock:playModeComplete pauseModeCompleteBlock:pauseModeComplete];
    });
}

#pragma mark -
#pragma mark -
#pragma mark -- KVO -----
#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == (__bridge void * _Nullable)([self class])) {
        if ([keyPath isEqualToString:@"isParsing"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([change[NSKeyValueChangeNewKey] boolValue]) {
                    [self.delegate onDLPStartLoading];
                } else {
                    [self.delegate onDLPStopLoading];
                }
            });
        } else if ([keyPath isEqualToString:@"buffered"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([change[NSKeyValueChangeNewKey] boolValue]) {
                    self->_playerState |= DLPlayerStateLoading;
                    [self.delegate onDLPStartLoading];
                } else {
                    self->_playerState &= ~DLPlayerStateLoading;
                    [self.delegate onDLPStopLoading];
                }
            });
        } else if ([keyPath isEqualToString:@"isEOF"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([change[NSKeyValueChangeNewKey] boolValue]) {
                    self->_playerState = DLPlayerStateEOF;
                    [self.delegate onPlayFinished];
                }
            });
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
