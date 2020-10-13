//
//  DLVideoOutput.h
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/19.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DLVideoOutputProtocol.h"

typedef NS_ENUM(NSUInteger, DLVideoOutputType) {
    DLVideoOutputTypeBase,
};

NS_ASSUME_NONNULL_BEGIN

@interface DLVideoOutput : NSObject <DLVideoOutputProtocol>

+ (instancetype)outputWithType:(DLVideoOutputType)type;

+ (id<DLVideoOutputProtocol>)videoOutputWithType:(DLVideoOutputType)type;

@end

NS_ASSUME_NONNULL_END
