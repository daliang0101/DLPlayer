//
//  DLDecoderCFunctions.h
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/21.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLDecoderCFunctions_h
#define DLDecoderCFunctions_h


static BOOL audioCodecIsSupported(AVCodecContext *audio)
{
//    if (audio->sample_fmt == AV_SAMPLE_FMT_S16) {
//        id<KxAudioManager> audioManager = [KxAudioManager audioManager];
//        return  (int)audioManager.samplingRate == audio->sample_rate &&
//        audioManager.numOutputChannels == audio->channels;
//    }
    return NO;
}

static void avStreamFPSTimeBase(AVStream *st, AVCodecContext *codecCtx, CGFloat defaultTimeBase, CGFloat *pFPS, CGFloat *pTimeBase)
{
    CGFloat fps, timebase;
    
    if (st->time_base.den && st->time_base.num)
        timebase = av_q2d(st->time_base);
    else if(codecCtx->time_base.den && codecCtx->time_base.num)
        timebase = av_q2d(codecCtx->time_base);
    else
        timebase = defaultTimeBase;
    
    if (st->avg_frame_rate.den && st->avg_frame_rate.num)
        fps = av_q2d(st->avg_frame_rate);
    else if (st->r_frame_rate.den && st->r_frame_rate.num)
        fps = av_q2d(st->r_frame_rate);
    else
        fps = 1.0 / timebase;
    
    if (pFPS)
        *pFPS = fps;
    if (pTimeBase)
        *pTimeBase = timebase;
}

static NSArray *collectStreams(AVFormatContext *formatCtx, enum AVMediaType codecType)  {
    NSMutableArray *ma = [NSMutableArray array];
    for (NSInteger i = 0; i < formatCtx->nb_streams; ++i)
        if (codecType == formatCtx->streams[i]->codecpar->codec_type)
            [ma addObject: [NSNumber numberWithInteger: i]];
    return [ma copy];
}

static NSData * copyFrameData(UInt8 *src, int linesize, int width, int height)  {
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength: width * height];
    Byte *dst = md.mutableBytes;
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}

static BOOL isNetworkPath (NSString *path)  {
    NSRange r = [path rangeOfString:@":"];
    if (r.location == NSNotFound) {
        return NO;
    }
    NSString *scheme = [path substringToIndex:r.length];
    if ([scheme isEqualToString:@"file"]) {
        return NO;
    }
    return YES;
}
//DLDecoderProtocol
static int interrupt_callback(void *ctx);
static int interrupt_callback(void *ctx)    {
    if (!ctx)
        return 0;
    __unsafe_unretained  id<DLDecoderProtocol> p = (__bridge id<DLDecoderProtocol>)ctx;
    const BOOL r = [p interruptDecoder];
    return r;
}

static void FFLog(void* context, int level, const char* format, va_list args) {
    @autoreleasepool {
        //Trim time at the beginning and new line at the end
//        NSString* message = [[NSString alloc] initWithFormat: [NSString stringWithUTF8String: format] arguments: args];
        switch (level) {
            case 0:
            case 1:
//                                NSLog(@"%@", [message stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]);
                break;
            case 2:
//                                NSLog(@"%@", [message stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]);
                break;
            case 3:
            case 4:
//                                NSLog(@"%@", [message stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]);
                break;
            default:
//                                NSLog(@"%@", [message stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]);
                break;
        }
    }
}

#endif /* DLDecoderCFunctions_h */
