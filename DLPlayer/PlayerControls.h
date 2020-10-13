//
//  PlayerControls.h
//  KxMovie_debug
//
//  Created by Daliang Cao on 2020/9/16.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PlayerControlsDelegate <NSObject>
- (void) playDidTouch: (BOOL) play;
- (void) doneDidTouch: (id) sender;
- (void) forwardDidTouch: (id) sender;
- (void) rewindDidTouch: (id) sender;
- (void) progressValueDidChange: (float) value;
@end

@interface PlayerControls : NSObject

@property (nonatomic, strong, readonly)     UIActivityIndicatorView     *activityIndicatorView;

@property (nonatomic, weak,  readwrite)     id<PlayerControlsDelegate>   delegate;

- (instancetype)initWithSuperView:(UIView *)superView playerView:(UIView *)playerView;

- (instancetype)initWithSuperView:(UIView *)superView
                       playerView:(UIView *)playerView
                         delegate:(_Nullable id<PlayerControlsDelegate>)delegate;

- (void)showHUD:(BOOL)show;

- (void)updateBottomBarWithPlayMode:(BOOL)isPlay;

- (void)updateHUD:(NSTimeInterval)duration position:(NSTimeInterval)position;

- (void)handlePlayFinished;

@end

NS_ASSUME_NONNULL_END
