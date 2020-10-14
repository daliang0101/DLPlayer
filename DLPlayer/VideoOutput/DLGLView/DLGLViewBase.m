//
//  DLGLViewBase.m
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLGLViewBase.h"

@implementation DLGLViewBase

@synthesize delegate;

- (instancetype)initWithFrame:(CGRect)frame {
    frame.size.width = MAX(1.0, frame.size.width);
    frame.size.height = MAX(1.0, frame.size.height);
    return [super initWithFrame:frame];
}

+ (Class) layerClass {
    return [CAEAGLLayer class];
}
- (void)layoutSubviews {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onGLViewLayoutSubviews)]) {
        [self.delegate onGLViewLayoutSubviews];
    }
}
- (void)setContentMode:(UIViewContentMode)contentMode {
    [super setContentMode:contentMode];
    if (self.delegate && [self.delegate respondsToSelector:@selector(onGLViewSetContentMode)]) {
        [self.delegate onGLViewSetContentMode];
    }
}

@end
