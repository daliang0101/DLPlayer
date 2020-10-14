//
//  DLPlayerController.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/19.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DLPlayerControllerProtocol.h"


typedef NS_ENUM(NSUInteger, DLPlayerControllerType) {
    DLPlayerControllerTypeBase,
};

NS_ASSUME_NONNULL_BEGIN

@interface DLPlayerController : NSObject <DLPlayerControllerProtocol>

+ (id<DLPlayerControllerProtocol>)controllerWithType:(DLPlayerControllerType)type;

+ (instancetype)playerControllerWithType:(DLPlayerControllerType)type;

@end

NS_ASSUME_NONNULL_END
