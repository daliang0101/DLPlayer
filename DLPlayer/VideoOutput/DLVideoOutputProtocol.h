//
//  DLVideoOutputProtocol.h
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/19.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLVideoOutputProtocol_h
#define DLVideoOutputProtocol_h
#import <CoreGraphics/CGGeometry.h>
#import "DLAVFrameProtocol.h"

@class UIView;
@protocol DLVideoOutputProtocol <NSObject>
@property (nonatomic, strong, readonly ) UIView               * _Nullable glView;
@property (nonatomic, assign, readwrite) CGRect               renderRect;

- (void)render:(nullable id<DLVideoFrameProtocol>)frame;

- (void)play;
- (void)pause;
- (void)stop;

- (void)setupVideoFormat:(DLVideoFrameFormat)videoFormat
               videoSize:(CGSize)videoSize;

@end

#endif /* DLVideoOutputProtocol_h */
