//
//  DLAVSynchronizer.h
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DLAVSynchronizerProtocol.h"

typedef NS_ENUM(NSUInteger, DLAVSynchronizerType) {
    DLAVSynchronizerTypeBase,
};

NS_ASSUME_NONNULL_BEGIN

@interface DLAVSynchronizer : NSObject <DLAVSynchronizerProtocol>

+ (instancetype)avSynchronizerWithType:(DLAVSynchronizerType)type;

+ (id<DLAVSynchronizerProtocol>)synchronizerWithType:(DLAVSynchronizerType)type;

@end

NS_ASSUME_NONNULL_END
