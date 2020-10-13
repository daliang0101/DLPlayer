//
//  DLAudioOutput.h
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DLAudioOutputProtocol.h"

typedef NS_ENUM(NSUInteger, DLAudioOutputType) {
    DLAudioOutputTypeAudioUnit,
};

NS_ASSUME_NONNULL_BEGIN

@interface DLAudioOutput : NSObject <DLAudioOutputProtocol>

+ (id<DLAudioOutputProtocol>)outputWithType:(DLAudioOutputType)type;

+ (instancetype)audioOutputWithType:(DLAudioOutputType)type;

@end

NS_ASSUME_NONNULL_END
