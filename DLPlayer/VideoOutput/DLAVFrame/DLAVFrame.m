//
//  DLAVFrame.m
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLAVFrame.h"
#import "DLAudioFrame.h"
#import "DLVideoFrame.h"
#import "DLVideoFrameRGB.h"
#import "DLVideoFrameYUV.h"
#import "DLSubtitleFrame.h"
#import "DLArtworkFrame.h"

@interface DLAVFrame ()
@property (nonatomic, strong) id<DLAVFrameProtocol> defaultAVFrame;
@end

@implementation DLAVFrame

@dynamic duration;
@dynamic position;
@dynamic type;
@dynamic format;

- (NSTimeInterval)duration {
    return _defaultAVFrame.duration;
}
- (void)setDuration:(NSTimeInterval)duration {
    _defaultAVFrame.duration = duration;
}
- (NSTimeInterval)position {
    return _defaultAVFrame.position;
}
- (void)setPosition:(NSTimeInterval)position {
    _defaultAVFrame.position = position;
}
- (DLAVFrameType)type {
    return _defaultAVFrame.type;
}
- (DLVideoFrameFormat)format {
    return _defaultAVFrame.format;
}

- (UIImage *)asImage {
    
    return nil;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setupDefaultFrame];
    }
    return self;
}

- (void)setupDefaultFrame {
    self.defaultAVFrame = (DLVideoFrame *)[[DLVideoFrameYUV alloc] init];
}

+ (id<DLAudioFrameProtocol>)audioFrame {
    return [[DLAudioFrame alloc] init];
}

+ (id<DLVideoFrameProtocol>)videoFrameWithFormat:(DLVideoFrameFormat)format {
    switch (format) {
        case DLVideoFrameFormatNone:
            return [[DLVideoFrameYUV alloc] init];
            break;
        case DLVideoFrameFormatRGB:
            return [[DLVideoFrameRGB  alloc] init];
            break;
        case DLVideoFrameFormatYUV:
            return [[DLVideoFrameYUV alloc] init];
            break;
        default:
            break;
    }
}

+ (id<DLAVFrameProtocol>)frameWithType:(DLAVFrameType)type {
    switch (type) {
        case DLAVFrameTypeAudio:
            return [self audioFrame];
            break;
        case DLAVFrameTypeSubtitle:
            return [[DLSubtitleFrame alloc] init];
            break;
        case DLAVFrameTypeArtwork:
            return [[DLArtworkFrame alloc] init];
            break;
        case DLAVFrameTypeVideo:
            return [self videoFrameWithFormat:DLVideoFrameFormatNone];
            break;
        default:
            break;
    }
}


@end
