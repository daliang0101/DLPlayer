//
//  DLRenderer.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DLRendererProtocol.h"

typedef NS_ENUM(NSUInteger, DLRendererType) {
    DLRendererTypeYUV,
    DLRendererTypeRGB,
};

NS_ASSUME_NONNULL_BEGIN

@interface DLRenderer : NSObject
+ (id<DLGLRendererProtocol>)rendererWithType:(DLRendererType)type;
@end

NS_ASSUME_NONNULL_END
