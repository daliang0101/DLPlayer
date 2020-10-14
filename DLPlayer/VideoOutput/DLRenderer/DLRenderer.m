//
//  DLRenderer.m
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLRenderer.h"
#import "DLRendererRGB.h"
#import "DLRendererYUV.h"

@implementation DLRenderer

+ (id<DLGLRendererProtocol>)rendererWithType:(DLRendererType)type {
    switch (type) {
        case DLRendererTypeRGB:
            return [[DLRendererRGB alloc] init];
            break;
        case DLRendererTypeYUV:
            return [[DLRendererYUV alloc] init];
            break;
        default:
            break;
    }
    return nil;
}

@end
