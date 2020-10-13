//
//  DLVideoFrameRGB.m
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLVideoFrameRGB.h"
#import <CoreGraphics/CGDataProvider.h>
#import <UIKit/UIImage.h>

@implementation DLVideoFrameRGB

@synthesize duration;
@synthesize position;
@dynamic type;

@dynamic format;
@synthesize height;
@synthesize width;

@synthesize linesize;

@synthesize rgb = _rgb;

- (DLVideoFrameFormat)format {
    return DLVideoFrameFormatRGB;
}
- (DLAVFrameType)type {
    return DLAVFrameTypeVideo;
}

- (UIImage *)asImage {
    UIImage *image = nil;
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(_rgb));
    if (provider) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace) {
            CGImageRef imageRef = CGImageCreate(self.width,
                                                self.height,
                                                8,
                                                24,
                                                self.linesize,
                                                colorSpace,
                                                kCGBitmapByteOrderDefault,
                                                provider,
                                                NULL,
                                                YES, // NO
                                                kCGRenderingIntentDefault);
            
            if (imageRef) {
                image = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
            }
            CGColorSpaceRelease(colorSpace);
        }
        CGDataProviderRelease(provider);
    }
    
    return image;
}

@end
