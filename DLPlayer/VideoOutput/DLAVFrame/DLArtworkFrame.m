//
//  DLArtworkFrame.m
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/21.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLArtworkFrame.h"

@implementation DLArtworkFrame

@synthesize duration;

@synthesize picture;

@synthesize position;

@dynamic type;

@dynamic format;

- (DLAVFrameType)type {
    return DLAVFrameTypeArtwork;
}
- (DLVideoFrameFormat)format {
    return DLVideoFrameFormatNone;
}

- (UIImage *)asImage {
    
    return nil;
}

@end
