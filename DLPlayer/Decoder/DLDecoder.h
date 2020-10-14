//
//  DLDecoder.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DLDecoderProtocol.h"

typedef NS_ENUM(NSUInteger, DLDecoderType) {
    DLDecoderTypeBase,
};

NS_ASSUME_NONNULL_BEGIN

@interface DLDecoder : NSObject <DLDecoderProtocol>

+ (id<DLDecoderProtocol>)decoderWithType:(DLDecoderType)type;

+ (instancetype)instanceDecoderWithType:(DLDecoderType)type;

@end

NS_ASSUME_NONNULL_END
