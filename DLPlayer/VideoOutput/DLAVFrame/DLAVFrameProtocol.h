//
//  DLAVFrameProtocol.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/19.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLPublicEnums_h
#define DLPublicEnums_h

typedef NS_ENUM(NSUInteger, DLAVFrameType) {
    DLAVFrameTypeAudio,
    DLAVFrameTypeVideo,
    DLAVFrameTypeSubtitle,
    DLAVFrameTypeArtwork,
};

typedef NS_ENUM(NSUInteger, DLVideoFrameFormat) {
    DLVideoFrameFormatNone,
    DLVideoFrameFormatRGB,
    DLVideoFrameFormatYUV,
};

@protocol DLAVFrameProtocol <NSObject>
@property (nonatomic, assign, readonly)     DLAVFrameType       type;
@property (nonatomic, assign, readonly)     DLVideoFrameFormat  format;
@property (nonatomic, assign, readwrite)    NSTimeInterval      position;
@property (nonatomic, assign, readwrite)    NSTimeInterval      duration;
@end


@protocol DLAudioFrameProtocol <DLAVFrameProtocol>
@property (nonatomic, copy) NSData *samples;
@end

@class UIImage;
@protocol DLArtworkFrameProtocol <DLAVFrameProtocol>
@property (nonatomic, copy) NSData *picture;
- (UIImage *) asImage;
@end

@protocol DLSubtitleFrameProtocol <DLAVFrameProtocol>
@property (nonatomic, copy) NSString *text;
@end


@protocol DLVideoFrameProtocol <DLAVFrameProtocol>
@property (nonatomic, assign) NSUInteger          width;
@property (nonatomic, assign) NSUInteger          height;
@end

@protocol DLVideoFrameYUVProtocol <DLVideoFrameProtocol>
@property (nonatomic, copy) NSData *luma;
@property (nonatomic, copy) NSData *chromaB;
@property (nonatomic, copy) NSData *chromaR;
@end

@protocol DLVideoFrameRGBProtocol <DLVideoFrameProtocol>
@property (nonatomic, assign) NSUInteger linesize;
@property (nonatomic, copy)   NSData     *rgb;
- (UIImage *) asImage;
@end


#endif /* DLPublicEnums_h */
