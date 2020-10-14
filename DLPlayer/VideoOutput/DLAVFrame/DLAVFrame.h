//
//  DLAVFrame.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DLAVFrameProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DLAVFrame : NSObject <DLAVFrameProtocol>

+ (id<DLAudioFrameProtocol>)audioFrame;

+ (id<DLVideoFrameProtocol>)videoFrameWithFormat:(DLVideoFrameFormat)format;

+ (id<DLAVFrameProtocol>)frameWithType:(DLAVFrameType)type;

@end

NS_ASSUME_NONNULL_END
