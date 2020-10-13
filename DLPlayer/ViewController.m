//
//  ViewController.m
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/19.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "ViewController.h"
#import "DLPlayerController.h"
#import "PlayerControls.h"

@interface ViewController () <PlayerControlsDelegate, DLPlayerControllerDelegate>
@property (nonatomic, strong) DLPlayerController *player;
@property (nonatomic, strong) PlayerControls     *playerControls;
@end

static const NSTimeInterval kRewindOrForwardTimeDuration = 10.0;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupPlayer];
}

- (void)setupPlayer {
    self.view.backgroundColor = [UIColor clearColor];
    
    DLPlayerController *player = [DLPlayerController playerControllerWithType:DLPlayerControllerTypeBase];
    player.playerView.frame = self.view.bounds;
    player.delegate = self;
    [self.view insertSubview:player.playerView atIndex:0];
    self.player = player;
    
    NSString *local = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"tblr2.mp4"];
//    NSString *cctv1_Live = @"http://ivi.bupt.edu.cn/hls/cctv1hd.m3u8";
    
    [player playPath:local];
    
    self.playerControls = [[PlayerControls alloc] initWithSuperView:self.view playerView:player.playerView delegate:self];
}

#pragma mark - PlayerControlsDelegate

- (void)playDidTouch:(BOOL)play {
    [_player playOrPause:play];
}

- (void)doneDidTouch:(id)sender {
    [_player stop];
    [self.playerControls updateBottomBarWithPlayMode:NO];
}

- (void)forwardDidTouch:(id)sender {
    [_player seekInterval:kRewindOrForwardTimeDuration];
}

- (void)rewindDidTouch:(id)sender {
    [_player seekInterval:-kRewindOrForwardTimeDuration];
}

- (void)progressValueDidChange:(float)value {
    [_player seekToRatio:value];
}

#pragma mark - DLPlayerControllerDelegate

- (void)onDLPProgressDidChange:(NSTimeInterval)duration position:(NSTimeInterval)position {
    [_playerControls updateHUD:duration position:position];
}
- (void)onDLPStartLoading {
    [_playerControls.activityIndicatorView startAnimating];
}
- (void)onDLPStopLoading {
    [_playerControls.activityIndicatorView stopAnimating];
}
- (void)onPlayFinished {
    [_playerControls handlePlayFinished];
}


@end
