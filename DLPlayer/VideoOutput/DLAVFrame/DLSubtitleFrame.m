//
//  DLSubtitleFrame.m
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/21.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLSubtitleFrame.h"

@implementation DLSubtitleFrame

@synthesize duration;

@synthesize position;

@synthesize text;

@dynamic type;

@dynamic format;

- (DLAVFrameType)type {
    return DLAVFrameTypeSubtitle;
}

- (DLVideoFrameFormat)format {
    return DLVideoFrameFormatNone;
}

@end
