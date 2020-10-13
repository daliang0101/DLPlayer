//
//  PlayerControls.m
//  KxMovie_debug
//
//  Created by Daliang Cao on 2020/9/16.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "PlayerControls.h"

static const CGFloat topH = 50;
static const CGFloat botH = 50;

static NSString * formatTimeInterval(CGFloat seconds, BOOL isLeft)
{
    seconds = MAX(0, seconds);
    
    NSInteger s = seconds;
    NSInteger m = s / 60;
    NSInteger h = m / 60;
    
    s = s % 60;
    m = m % 60;
    
    NSMutableString *format = [(isLeft && seconds >= 0.5 ? @"-" : @"") mutableCopy];
    if (h != 0) {
        [format appendFormat:@"%ld:%0.2ld", (long)h, (long)m];
    } else {
        [format appendFormat:@"%ld", (long)m];
    }
    [format appendFormat:@":%0.2ld", (long)s];
    
    return format;
}

@interface PlayerControls ()

@property (nonatomic, weak)   UIView                    *superView;
@property (nonatomic, weak)   UIView                    *playerView;
@property (nonatomic, strong) UIView                    *topHUD;

@property (nonatomic, strong) UIToolbar                 *topBar;
@property (nonatomic, strong) UIToolbar                 *bottomBar;
@property (nonatomic, strong) UISlider                  *progressSlider;

@property (nonatomic, weak  ) UIBarButtonItem           *playPauseBtn;
@property (nonatomic, strong) UIBarButtonItem           *playBtn;
@property (nonatomic, strong) UIBarButtonItem           *pauseBtn;
@property (nonatomic, strong) UIBarButtonItem           *rewindBtn;
@property (nonatomic, strong) UIBarButtonItem           *fforwardBtn;
@property (nonatomic, strong) UIBarButtonItem           *spaceItem;
@property (nonatomic, strong) UIBarButtonItem           *fixedSpaceItem;

@property (nonatomic, strong) UIButton                  *doneButton;
@property (nonatomic, strong) UILabel                   *progressLabel;
@property (nonatomic, strong) UILabel                   *leftLabel;

@property (nonatomic, strong) UIActivityIndicatorView   *activityIndicatorView;

@property (nonatomic, strong) UITapGestureRecognizer    *tapGestureRecognizer;

@property (nonatomic, assign) BOOL                       hiddenHUD;
@property (nonatomic, assign) CGFloat                    width;
@property (nonatomic, assign) CGFloat                    height;

@end

@implementation PlayerControls

- (instancetype)initWithSuperView:(UIView *)superView playerView:(UIView *)playerView {
    return [self initWithSuperView:superView playerView:playerView delegate:nil];
}

- (instancetype)initWithSuperView:(UIView *)superView
                       playerView:(UIView *)playerView
                         delegate:(_Nullable id<PlayerControlsDelegate>)delegate
{
    if (self = [super init]) {
        _width = [UIScreen mainScreen].bounds.size.width;
        _height = [UIScreen mainScreen].bounds.size.height;
        _superView = superView;
        _playerView = playerView;
        _delegate = delegate;
        [self setupControlsForView:superView];
        [self setupGesturesForView:playerView];
    }
    return self;
}

#pragma mark - setup subviews

- (void)setupControlsForView:(UIView *)targetView {
    [targetView addSubview:self.activityIndicatorView];
    [targetView addSubview:self.topBar];
    [targetView addSubview:self.topHUD];
    [targetView addSubview:self.bottomBar];

    [self.topHUD addSubview:self.doneButton];
    [self.topHUD addSubview:self.progressLabel];
    [self.topHUD addSubview:self.progressSlider];
    [self.topHUD addSubview:self.leftLabel];

    self.playPauseBtn = self.playBtn;
    [self updateBottomBar];
}

- (UIView *)topHUD {
    if (!_topHUD) {
        CGFloat width = self.width;
        _topHUD = [[UIView alloc] initWithFrame:CGRectZero];
        _topHUD.frame = CGRectMake(0, 0, width, self.topBar.frame.size.height);
        _topHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    return _topHUD;
}
- (UIToolbar *)topBar {
    if (!_topBar) {
        CGFloat width = self.width;
        _topBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, width, topH)];
        _topBar.tintColor = [UIColor whiteColor];
        _topBar.barTintColor = [UIColor clearColor];
        _topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    return _topBar;
}
- (UIToolbar *)bottomBar {
    if (!_bottomBar) {
        CGFloat width = _superView.frame.size.width;
        CGFloat height = self.height;
        _bottomBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, height-botH, width, botH)];
        _bottomBar.tintColor = [UIColor whiteColor];
        _bottomBar.barTintColor = [UIColor clearColor];
        _bottomBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    }
    return _bottomBar;
}
- (UIButton *)doneButton {
    if (!_doneButton) {
        _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _doneButton.frame = CGRectMake(0, 1, 50, topH);
        [_doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_doneButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        _doneButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _doneButton.showsTouchWhenHighlighted = YES;
        [_doneButton addTarget:self action:@selector(doneDidTouch:)
             forControlEvents:UIControlEventTouchUpInside];
        [_doneButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    }
    return _doneButton;
}
- (UILabel *)progressLabel {
    if (!_progressLabel) {
        _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(46, 1, 50, topH)];
        _progressLabel.backgroundColor = [UIColor clearColor];
        _progressLabel.opaque = NO;
        _progressLabel.adjustsFontSizeToFitWidth = NO;
        _progressLabel.textAlignment = NSTextAlignmentRight;
        _progressLabel.textColor = [UIColor whiteColor];
        _progressLabel.text = @"";
        _progressLabel.font = [UIFont systemFontOfSize:12];
    }
    return _progressLabel;
}
- (UISlider *)progressSlider {
    if (!_progressSlider) {
        CGFloat width = self.width;
        _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(100, 2, width-197, topH)];
        _progressSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _progressSlider.continuous = NO;
        _progressSlider.value = 0;
        [_progressSlider addTarget:self
                            action:@selector(progressDidChange:)
                  forControlEvents:UIControlEventValueChanged];
    }
    return _progressSlider;
}
- (UILabel *)leftLabel {
    if (!_leftLabel) {
        CGFloat width = self.width;
        _leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(width-92, 1, 60, topH)];
        _leftLabel.backgroundColor = [UIColor clearColor];
        _leftLabel.opaque = NO;
        _leftLabel.adjustsFontSizeToFitWidth = NO;
        _leftLabel.textAlignment = NSTextAlignmentLeft;
        _leftLabel.textColor = [UIColor whiteColor];
        _leftLabel.text = @"";
        _leftLabel.font = [UIFont systemFontOfSize:12];
        _leftLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    }
    return _leftLabel;
}
- (UIActivityIndicatorView *)activityIndicatorView {
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicatorView.center = _superView.center;
        _activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    }
    return _activityIndicatorView;
}

- (UIBarButtonItem *)spaceItem {
    if (!_spaceItem) {
        _spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                   target:nil
                                                                   action:nil];
    }
    return _spaceItem;
}
- (UIBarButtonItem *)fixedSpaceItem {
    if (!_fixedSpaceItem) {
        _fixedSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                        target:nil
                                                                        action:nil];
        _fixedSpaceItem.width = 30;
    }
    return _fixedSpaceItem;
}
- (UIBarButtonItem *)rewindBtn {
    if (!_rewindBtn) {
        _rewindBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                                                                   target:self
                                                                   action:@selector(rewindDidTouch:)];
    }
    return _rewindBtn;
}
- (UIBarButtonItem *)playBtn {
    if (!_playBtn) {
        _playBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                                 target:self
                                                                 action:@selector(playDidTouch:)];
        _playBtn.width = 50;
    }
    return _playBtn;
}
- (UIBarButtonItem *)pauseBtn {
    if (!_pauseBtn) {
        _pauseBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                                                                 target:self
                                                                 action:@selector(playDidTouch:)];
        _pauseBtn.width = 50;
    }
    return _pauseBtn;
}
- (UIBarButtonItem *)fforwardBtn {
    if (!_fforwardBtn) {
        _fforwardBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward
                                                                  target:self
                                                                  action:@selector(forwardDidTouch:)];
        _fforwardBtn.width = 50;
    }
    return _fforwardBtn;
}

- (void)updateBottomBar {
    self.playPauseBtn = (_playPauseBtn == self.pauseBtn) ? self.playBtn : self.pauseBtn;
    [self.bottomBar setItems:@[self.spaceItem, self.rewindBtn, self.fixedSpaceItem, _playPauseBtn,
                           self.fixedSpaceItem, self.fforwardBtn, self.spaceItem] animated:NO];
}

#pragma mark - Setup Gestures

- (void)setupGesturesForView:(UIView *)gestureView {
    [gestureView addGestureRecognizer:self.tapGestureRecognizer];
}

- (UITapGestureRecognizer *)tapGestureRecognizer {
    if (!_tapGestureRecognizer) {
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _tapGestureRecognizer.numberOfTapsRequired = 1;
    }
    return _tapGestureRecognizer;
}

#pragma mark - Public

- (void)showHUD:(BOOL)show {
    _hiddenHUD = !show;
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:_hiddenHUD];
    
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         CGFloat alpha = self->_hiddenHUD ? 0 : 1;
                         self->_topBar.alpha = alpha;
                         self->_topHUD.alpha = alpha;
                         self->_bottomBar.alpha = alpha;
                     }
                     completion:nil];
    
}

- (void)updateBottomBarWithPlayMode:(BOOL)isPlay {
    self.playPauseBtn = isPlay ? self.pauseBtn : self.playBtn;
    [self.bottomBar setItems:@[self.spaceItem, self.rewindBtn, self.fixedSpaceItem, _playPauseBtn,
                               self.fixedSpaceItem, self.fforwardBtn, self.spaceItem] animated:NO];
}

- (void)updateHUD:(NSTimeInterval)duration position:(NSTimeInterval)position {
    if (_progressSlider.state == UIControlStateNormal) {
        _progressSlider.value = position / duration;
    }
    _progressLabel.text = formatTimeInterval(position, NO);
    if (duration != MAXFLOAT) {
        _leftLabel.text = formatTimeInterval(duration - position, YES);
    }
}

- (void)handlePlayFinished {
    [_activityIndicatorView stopAnimating];
    self.playPauseBtn = _pauseBtn;
    [self updateBottomBar];
}

#pragma mark - Gesture method

- (void)handleTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (sender == _tapGestureRecognizer) {
            [self showHUD: _hiddenHUD];
        }
    }
}

#pragma mark - Button method

- (void) playDidTouch: (id) sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playDidTouch:)]) {
        [self.delegate playDidTouch:(_playPauseBtn == self.playBtn)];
    }
    [self updateBottomBar];
}

- (void) doneDidTouch: (id) sender  {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playDidTouch:)]) {
        [self.delegate doneDidTouch:sender];
    }
}

- (void) forwardDidTouch: (id) sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(forwardDidTouch:)]) {
        [self.delegate forwardDidTouch:sender];
    }
}
- (void) rewindDidTouch: (id) sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewindDidTouch:)]) {
        [self.delegate rewindDidTouch:sender];
    }
}
- (void) progressDidChange: (id) sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(progressValueDidChange:)]) {
        [self.delegate progressValueDidChange:((UISlider *)sender).value];
    }
}

@end

