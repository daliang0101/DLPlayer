//
//  DLGLView.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DLGLViewProtocol.h"

typedef NS_ENUM(NSUInteger, DLGLViewType) {
    DLGLViewTypeBase,
};

NS_ASSUME_NONNULL_BEGIN

@class UIView;

@interface DLGLView : NSObject

+ (UIView<DLGLViewProtocol> *)glViewWithType:(DLGLViewType)type;

@end

NS_ASSUME_NONNULL_END
