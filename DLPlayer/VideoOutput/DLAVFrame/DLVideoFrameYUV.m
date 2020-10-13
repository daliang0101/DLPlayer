//
//  DLVideoFrameYUV.m
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLVideoFrameYUV.h"

@implementation DLVideoFrameYUV

@synthesize duration;
@synthesize position;
@dynamic type;

@dynamic format;
@synthesize height;
@synthesize width;

@synthesize chromaB;
@synthesize chromaR;
@synthesize luma;

- (DLVideoFrameFormat)format {
    return DLVideoFrameFormatYUV;
}
- (DLAVFrameType)type {
    return DLAVFrameTypeVideo;
}

@end
