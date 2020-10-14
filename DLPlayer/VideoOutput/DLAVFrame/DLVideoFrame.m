//
//  DLVideoFrame.m
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLVideoFrame.h"

@implementation DLVideoFrame

@synthesize duration;
@synthesize position;
@dynamic type;

@dynamic format;
@synthesize height;
@synthesize width;

- (DLAVFrameType)type {
    return DLAVFrameTypeVideo;
}
- (DLVideoFrameFormat)format {
    return DLVideoFrameFormatNone;
}

@end
