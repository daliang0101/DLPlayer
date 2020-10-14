//
//  DLPlayerController.m
//  DLPlayer
//
//  Created by Daliang on 2020/9/19.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLPlayerController.h"
#import "DLPlayerControllerBase.h"

@interface DLPlayerController ()
@property (nonatomic, strong) id<DLPlayerControllerProtocol> defaultPlayerVC;
@end

@implementation DLPlayerController

@dynamic playerView;

- (instancetype)init {
    if (self = [super init]) {
        [self setupDefaultPlayerVC];
    }
    return self;
}

- (void)setupDefaultPlayerVC {
    self.defaultPlayerVC = [[DLPlayerControllerBase alloc] init];
}

+ (id<DLPlayerControllerProtocol>)controllerWithType:(DLPlayerControllerType)type {
    switch (type) {
        case DLPlayerControllerTypeBase:
            return [[DLPlayerControllerBase alloc] init];
            break;
            
        default:
            return [[DLPlayerControllerBase alloc] init];
            break;
    }
    return nil;
}

+ (instancetype)playerControllerWithType:(DLPlayerControllerType)type {
    return [self controllerWithType:type];
}

#pragma mark - Playback

- (void)prepareToPlayPath:(NSString *)path {
    [_defaultPlayerVC prepareToPlayPath:path];
}

- (void)playPath:(NSString *)path {
    [_defaultPlayerVC playPath:path];
}

- (void)seekInterval:(NSTimeInterval)interval {
    [_defaultPlayerVC seekInterval:interval];
}

- (void)seekToRatio:(float)ratio {
    [_defaultPlayerVC seekToRatio:ratio];
}

- (UIView *)playerView {
    return _defaultPlayerVC.playerView;
}

- (void)stop {
    [_defaultPlayerVC stop];
}

- (void)handleReceiveMemoryWarning {
    [_defaultPlayerVC handleReceiveMemoryWarning];
}

- (void)playOrPause:(BOOL)play {
    [_defaultPlayerVC playOrPause:play];
}

@end

