//
//  DLVideoOutput.m
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/19.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLVideoOutput.h"
#import "DLVideoOutputBase.h"

@interface DLVideoOutput ()
@property (nonatomic, strong) id<DLVideoOutputProtocol> defaultVideoOutput;
@end

@implementation DLVideoOutput

@dynamic glView;
@dynamic renderRect;

- (CGRect)renderRect {
    return _defaultVideoOutput.renderRect;
}
- (void)setRenderRect:(CGRect)renderRect {
    _defaultVideoOutput.renderRect = renderRect;
}
- (UIView *)glView {
    return _defaultVideoOutput.glView;
}

- (instancetype)init {
    if (self = [super init]) {
        _defaultVideoOutput = [[DLVideoOutputBase alloc] init];
    }
    return self;
}

+ (instancetype)outputWithType:(DLVideoOutputType)type {
    return (DLVideoOutput *)[self videoOutputWithType:type];
}

+ (id<DLVideoOutputProtocol>)videoOutputWithType:(DLVideoOutputType)type {
    switch (type) {
        case DLVideoOutputTypeBase:
            return [[DLVideoOutputBase alloc] init];
            break;
            
        default:
            return [[DLVideoOutputBase alloc] init];
            break;
    }
    return nil;
}

- (void)render:(nullable id<DLVideoFrameProtocol>)frame {
    [_defaultVideoOutput render:frame];
}

- (void)setupVideoFormat:(DLVideoFrameFormat)videoFormat
               videoSize:(CGSize)videoSize
{
    [_defaultVideoOutput setupVideoFormat:videoFormat videoSize:videoSize];
}

- (void)play {
    [_defaultVideoOutput play];
}
- (void)stop {
    [_defaultVideoOutput stop];
}
- (void)pause {
    [_defaultVideoOutput pause];
}

@end
