//
//  DLPlayerControllerProtocol.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLPlayerControllerProtocol_h
#define DLPlayerControllerProtocol_h


#pragma mark - DLPlayerControllerDelegate

@protocol DLPlayerControllerDelegate <NSObject>
@optional
- (void)onDLPStartLoading;
- (void)onDLPStopLoading;
- (void)onPlayFinished;
- (void)onDLPProgressDidChange:(NSTimeInterval)duration position:(NSTimeInterval)position;
@end

#pragma mark - DLPlayerControllerProtocol

@class UIView;
@protocol DLPlayerControllerProtocol <NSObject>

@property (nonatomic, readonly) UIView        *playerView;

/**
 * Only prepare resource, call 'playOrPause:' to start play procedure
 */
- (void)prepareToPlayPath:(NSString *)path;

/**
 * Auto play on 'path'
 */
- (void)playPath:(NSString *)path;

/**
 * @param play 'YES' to process 'play' func, 'NO' process to 'pause' func
 */
- (void)playOrPause:(BOOL)play;

- (void)stop;

- (void)seekToRatio:(float)ratio;
- (void)seekInterval:(NSTimeInterval)interval;

@optional

@property (nonatomic, weak) id<DLPlayerControllerDelegate> delegate;

@property (nonatomic, assign)           BOOL                        mute;

- (void)handleReceiveMemoryWarning;

@end

#endif /* DLPlayerControllerProtocol_h */
