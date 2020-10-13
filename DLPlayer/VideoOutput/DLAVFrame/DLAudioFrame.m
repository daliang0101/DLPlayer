//
//  DLAudioFrame.m
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLAudioFrame.h"

@implementation DLAudioFrame

@synthesize duration;

@synthesize position;

@dynamic type;

@dynamic format;

@synthesize samples;

- (DLAVFrameType)type {
    return DLAVFrameTypeAudio;
}
- (DLVideoFrameFormat)format {
    return DLVideoFrameFormatNone;
}

@end
