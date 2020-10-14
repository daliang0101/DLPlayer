//
//  DLGLView.m
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLGLView.h"
#import "DLGLViewBase.h"

@implementation DLGLView

+ (UIView<DLGLViewProtocol> *)glViewWithType:(DLGLViewType)type {
    switch (type) {
        case DLGLViewTypeBase:
            return [[DLGLViewBase alloc] init];
            break;
            
        default:
            return [[DLGLViewBase alloc] init];
            break;
    }
    return nil;
}

@end
