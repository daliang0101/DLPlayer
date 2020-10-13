//
//  DLDecoderBase.m
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLDecoderBase.h"
#import "DLDecoderPrivateProtocol.h"
#import "DLDecoderCFunctions.h"
#import "DlDecoderErrorDefines.h"
#import "DLAVFrameSubtitleaASSParser.h"
#import "DLAVFrame.h"

@interface DLDecoderBase () <DLDecoderPrivateProtocol>
@end

@implementation DLDecoderBase

DECODER_PROPERTIES_COMPILEOPTIONS_SETUP

DECODER_PRIVATE_PROPERTIES_COMPILEOPTIONS_SETUP

#pragma mark - Init

+ (void)initialize  {
    av_log_set_callback(FFLog);
    avformat_network_init();
}

- (void) dealloc    {
    NSLog(@"%@ dealloc", self);
    [self closeFile];
}

#pragma mark - DecoderProtocol's public methods

- (void)closeFile {
    [self closeAudioStream];
    [self closeVideoStream];
    [self closeSubtitleStream];
    
    self.videoStreams = nil;
    self.audioStreams = nil;
    self.subtitleStreams = nil;
    self.videoFrameFormat  = DLVideoFrameFormatNone;
    
    if (_formatCtx) {
        _formatCtx->interrupt_callback.opaque = NULL;
        _formatCtx->interrupt_callback.callback = NULL;
        avformat_close_input(&_formatCtx);
        self.formatCtx = NULL;
    }
}

- (NSArray *)decodeFrames:(NSTimeInterval)minDuration {
    if (_videoStream == -1 && _audioStream == -1)   {
        return nil;
    }
    NSMutableArray *result = [NSMutableArray array];
    AVPacket packet;
    CGFloat decodedDuration = 0;
    BOOL finished = NO;
    // 解封装、解码，放在一个线程顺序执行
    while (!finished) {
        // 解封装
        if (av_read_frame(_formatCtx, &packet) < 0) {
            _isEOF = YES;
            if (self.eofCallback) {
                self.eofCallback(YES);
            }
            break;
        }
        if (_videoStream == -1 && _audioStream == -1)   {
            break;
        }
        // 解码
        if (packet.stream_index ==_videoStream) {
            int decodeFinished = avcodec_send_packet(_videoCodecCtx, &packet);
            while (!decodeFinished) {
                if (_videoStream == -1 && _audioStream == -1)   {
                    break;
                }
                decodeFinished = avcodec_receive_frame(_videoCodecCtx, _videoFrame);
                if (!decodeFinished) {
                    id<DLVideoFrameProtocol> frame = [self handleVideoFrame];
                    if (frame) {
                        [result addObject:frame];
                        _position = frame.position;
                        decodedDuration += frame.duration;
                        if (decodedDuration > minDuration) {
                            finished = YES;
                        }
                    }
                }
            }
        } else if (packet.stream_index == _audioStream) {
            int decodeFinished = avcodec_send_packet(_audioCodecCtx, &packet);
            while (!decodeFinished) {
                if (_videoStream == -1 && _audioStream == -1)   {
                    break;
                }
                decodeFinished = avcodec_receive_frame(_audioCodecCtx, _audioFrame);
                if (decodeFinished == AVERROR_EOF || decodeFinished == AVERROR(EAGAIN)) {
                    finished = YES;
                    break;
                }
                id<DLAudioFrameProtocol> frame = [self handleAudioFrame];
                if (frame) {
                    [result addObject:frame];
                    if (_videoStream == -1) {
                        _position = frame.position;
                        decodedDuration += frame.duration;
                        if (decodedDuration > minDuration)
                            finished = YES;
                    }
                }
            }
        } else if (packet.stream_index == _artworkStream) {
            if (_videoStream == -1 && _audioStream == -1)   {
                break;
            }
            if (packet.size) {
                id<DLArtworkFrameProtocol> frame = (id<DLArtworkFrameProtocol>)[DLAVFrame frameWithType:DLAVFrameTypeArtwork];
                frame.picture = [NSData dataWithBytes:packet.data length:packet.size];
                [result addObject:frame];
            }
        } else if (packet.stream_index == _subtitleStream) {
            int pktSize = packet.size;
            while (pktSize > 0) {
                if (_videoStream == -1 && _audioStream == -1)   {
                    break;
                }
                AVSubtitle subtitle;
                int gotsubtitle = 0;
                int len = avcodec_decode_subtitle2(_subtitleCodecCtx,
                                                   &subtitle,
                                                   &gotsubtitle,
                                                   &packet);
                if (len < 0) {
                    NSLog(@"decode subtitle error, skip packet");
                    break;
                }
                if (gotsubtitle) {
                    id<DLSubtitleFrameProtocol> frame = [self handleSubtitle: &subtitle];
                    if (frame) {
                        [result addObject:frame];
                    }
                    avsubtitle_free(&subtitle);
                }
                if (0 == len)
                    break;
                pktSize -= len;
            }
        }
        av_packet_unref(&packet);
    }
    return result;
}

- (DLVideoFrameFormat)getFrameFormat {
    return _videoFrameFormat;
}

- (BOOL)interruptDecoder {
    return _interruptCallback ? _interruptCallback() : NO;
}

- (BOOL)openFile:(NSString *)path error:(NSError *__autoreleasing *)perror {
    NSAssert(path, @"nil path");
    NSAssert(!_formatCtx, @"already open");
    
    _isNetwork = isNetworkPath(path);
    
    static BOOL needNetworkInit = YES;
    if (needNetworkInit && _isNetwork) {
        needNetworkInit = NO;
        avformat_network_init();
    }
    
    _path = path;
    
    DLDecoderError errCode = [self openInput: path];
    
    if (errCode == DLDecoderErrorNone) {
        DLDecoderError videoErr = [self openVideoStream];
        DLDecoderError audioErr = [self openAudioStream];
        _subtitleStream = -1;
        if (videoErr != DLDecoderErrorNone && audioErr != DLDecoderErrorNone) {
            errCode = videoErr; // both fails
        } else {
            _subtitleStreams = collectStreams(_formatCtx, AVMEDIA_TYPE_SUBTITLE);
        }
    }
    if (errCode != DLDecoderErrorNone) {
        [self closeFile];
        NSString *errMsg = errorMessage(errCode);
        NSLog(@"%@, %@", errMsg, path.lastPathComponent);
        if (perror) {
            *perror = kxmovieError(errCode, errMsg);
        }
        return NO;
    }
    return YES;
}

- (BOOL)setupVideoFrameFormat:(DLVideoFrameFormat)format {
    if (format == DLVideoFrameFormatYUV &&  _videoCodecCtx &&
        (_videoCodecCtx->pix_fmt == AV_PIX_FMT_YUV420P || _videoCodecCtx->pix_fmt == AV_PIX_FMT_YUVJ420P))
    {
        self.videoFrameFormat = DLVideoFrameFormatYUV;
        return YES;
    }
    self.videoFrameFormat = DLVideoFrameFormatRGB;
    return _videoFrameFormat == format;
}

- (NSTimeInterval) duration    {   // 通过ffmepg打开的多媒体文件上下文对象，返回多媒体文件的总时长
    if (!_formatCtx)
        return 0;
    if (_formatCtx->duration == AV_NOPTS_VALUE)
        return MAXFLOAT;
    return (CGFloat)_formatCtx->duration / AV_TIME_BASE;
    
}

- (NSUInteger) frameWidth   {  // 用ffmpeg视频解码上下文，返回视频宽
    return _videoCodecCtx ? _videoCodecCtx->width : 0;
}

- (NSUInteger) frameHeight  {   // 用ffmpeg视频解码上下文，返回视频高
    return _videoCodecCtx ? _videoCodecCtx->height : 0;
}

- (CGFloat) sampleRate  {   // 用ffmpeg音频解码上下文，返回音频采样率
    return _audioCodecCtx ? _audioCodecCtx->sample_rate : 0;
}

- (NSUInteger) audioStreamsCount    {   // 返回音频流数量
    return [_audioStreams count];
}

- (NSUInteger) subtitleStreamsCount {   // 返回字幕流数量
    return [_subtitleStreams count];
}

- (NSInteger) selectedAudioStream   {   // 返回选中的音频流索引值
    if (_audioStream == -1)
        return -1;
    NSNumber *n = [NSNumber numberWithInteger:_audioStream];
    return [_audioStreams indexOfObject:n];
}

- (NSInteger) selectedSubtitleStream    {
    if (_subtitleStream == -1)
        return -1;
    return [_subtitleStreams indexOfObject:@(_subtitleStream)];
}

- (BOOL) validAudio {
    return _audioStream != -1;
}

- (BOOL) validVideo {
    return _videoStream != -1;
}

- (BOOL) validSubtitles {
    return _subtitleStream != -1;
}

- (NSDictionary *) info {
    if (!_info) {
        NSMutableDictionary *md = [NSMutableDictionary dictionary];
        if (_formatCtx) {
            const char *formatName = _formatCtx->iformat->name;
            [md setValue: [NSString stringWithCString:formatName encoding:NSUTF8StringEncoding]
                  forKey: @"format"];
            if (_formatCtx->bit_rate) {
                [md setValue: [NSNumber numberWithLongLong:_formatCtx->bit_rate]
                      forKey: @"bitrate"];
            }
            if (_formatCtx->metadata) {
                NSMutableDictionary *md1 = [NSMutableDictionary dictionary];
                AVDictionaryEntry *tag = NULL;
                while((tag = av_dict_get(_formatCtx->metadata, "", tag, AV_DICT_IGNORE_SUFFIX))) {
                    [md1 setValue: [NSString stringWithCString:tag->value encoding:NSUTF8StringEncoding]
                           forKey: [NSString stringWithCString:tag->key encoding:NSUTF8StringEncoding]];
                }
                [md setValue: [md1 copy] forKey: @"metadata"];
            }
            char buf[256];
            
            if (_videoStreams.count) {
                NSMutableArray *ma = [NSMutableArray array];
                for (NSNumber *n in _videoStreams) {
                    if(n.intValue >= 0 && n.intValue < _formatCtx->nb_streams) {
                        AVCodecContext *codecCtx = NULL;
                        codecCtx = avcodec_alloc_context3(NULL);
                        int ret = avcodec_parameters_to_context(codecCtx, _formatCtx->streams[n.intValue]->codecpar);
                        if (ret < 0) {
                            NSLog(@"DLDecoderErrorFillCodecContext");
                            continue;
                        }
                        avcodec_string(buf, sizeof(buf), codecCtx, 1);
                        NSString *s = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
                        if ([s hasPrefix:@"Video: "])
                            s = [s substringFromIndex:@"Video: ".length];
                        [ma addObject:s];
                    }
                }
                md[@"video"] = ma.copy;
            }
            if (_audioStreams.count) {
                NSMutableArray *ma = [NSMutableArray array];
                for (NSNumber *n in _audioStreams) {
                    if(n.intValue >= 0 && n.intValue < _formatCtx->nb_streams) {
                        AVCodecContext *codecCtx = NULL;
                        codecCtx = avcodec_alloc_context3(NULL);
                        int ret = avcodec_parameters_to_context(codecCtx, _formatCtx->streams[n.intValue]->codecpar);
                        if (ret < 0) {
                            NSLog(@"DLDecoderErrorFillCodecContext");
                            continue;
                        }
                        
                        AVStream *st = _formatCtx->streams[n.integerValue];
                        NSMutableString *ms = [NSMutableString string];
                        AVDictionaryEntry *lang = av_dict_get(st->metadata, "language", NULL, 0);
                        if (lang && lang->value) {
                            [ms appendFormat:@"%s ", lang->value];
                        }
                        
                        avcodec_string(buf, sizeof(buf), codecCtx, 1);
                        NSString *s = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
                        if ([s hasPrefix:@"Audio: "]) {
                            s = [s substringFromIndex:@"Audio: ".length];
                        }
                        [ms appendString:s];
                        [ma addObject:ms.copy];
                    }
                }
                md[@"audio"] = ma.copy;
            }
            if (_subtitleStreams.count) {
                NSMutableArray *ma = [NSMutableArray array];
                for (NSNumber *n in _subtitleStreams) {
                    
                    if(n.intValue >= 0 && n.intValue < _formatCtx->nb_streams) {
                        AVCodecContext *codecCtx = NULL;
                        codecCtx = avcodec_alloc_context3(NULL);
                        int ret = avcodec_parameters_to_context(codecCtx, _formatCtx->streams[n.intValue]->codecpar);
                        if (ret < 0) {
                            NSLog(@"DLDecoderErrorFillCodecContext");
                            continue;
                        }
                        
                        AVStream *st = _formatCtx->streams[n.integerValue];
                        NSMutableString *ms = [NSMutableString string];
                        AVDictionaryEntry *lang = av_dict_get(st->metadata, "language", NULL, 0);
                        if (lang && lang->value) {
                            [ms appendFormat:@"%s ", lang->value];
                        }
                        
                        avcodec_string(buf, sizeof(buf), codecCtx, 1);
                        NSString *s = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
                        if ([s hasPrefix:@"Subtitle: "]) {
                            s = [s substringFromIndex:@"Subtitle: ".length];
                        }
                        [ms appendString:s];
                        [ma addObject:ms.copy];
                    }
                }
                md[@"subtitles"] = ma.copy;
            }
        }
        _info = [md copy];
    }
    return _info;
}

- (NSString *) videoStreamFormatName    {
    if (!_videoCodecCtx)
        return nil;
    if (_videoCodecCtx->pix_fmt == AV_PIX_FMT_NONE)
        return @"";
    const char *name = av_get_pix_fmt_name(_videoCodecCtx->pix_fmt);
    return name ? [NSString stringWithCString:name encoding:NSUTF8StringEncoding] : @"?";
}

- (NSTimeInterval) startTime   {
    if (_videoStream != -1) {
        AVStream *st = _formatCtx->streams[_videoStream];
        if (AV_NOPTS_VALUE != st->start_time)
            return st->start_time * _videoTimeBase;
        return 0;
    }
    if (_audioStream != -1) {
        AVStream *st = _formatCtx->streams[_audioStream];
        if (AV_NOPTS_VALUE != st->start_time)
            return st->start_time * _audioTimeBase;
        return 0;
    }
    return 0;
}

- (void) setPosition: (NSTimeInterval)seconds  {
    _position = seconds;
    _isEOF = NO;
    if (self.eofCallback) {
        self.eofCallback(NO);
    }
    if (_videoStream != -1) {
        int64_t ts = (int64_t)(seconds / _videoTimeBase);
        avformat_seek_file(_formatCtx, (int)_videoStream, ts, ts, ts, AVSEEK_FLAG_FRAME);
        avcodec_flush_buffers(_videoCodecCtx);  // 解码seek过程，要清空ffmpeg解码上下文内部缓冲
    }
    if (_audioStream != -1) {
        int64_t ts = (int64_t)(seconds / _audioTimeBase);   // 用ffmpeg对文件执行seek动作
        avformat_seek_file(_formatCtx, (int)_audioStream, ts, ts, ts, AVSEEK_FLAG_FRAME);
        avcodec_flush_buffers(_audioCodecCtx);
    }
}

- (void) setSelectedSubtitleStream:(NSInteger)selected  {
    [self closeSubtitleStream];
    if (selected == -1) {
        _subtitleStream = -1;
    } else {
        NSInteger subtitleStream = [_subtitleStreams[selected] integerValue];
        DLDecoderError errCode = [self openSubtitleStream:subtitleStream];
        if (DLDecoderErrorNone != errCode) {
            NSLog(@"%@", errorMessage(errCode));
        }
    }
}

#pragma mark - DecoderProtocol's private methods

- (DLDecoderError) openInput: (NSString *) path   {
    AVFormatContext *formatCtx = NULL;
    if (_interruptCallback) {   // 设置I/O回调
        formatCtx = avformat_alloc_context();
        if (!formatCtx) {
            return DLDecoderErrorOpenFile;
        }
        AVIOInterruptCB cb = {interrupt_callback, (__bridge void *)(self)};
        formatCtx->interrupt_callback = cb; // 设置I/O 回调，必须在avformat_open_input之前设置
    }
    if (avformat_open_input(&formatCtx, [path cStringUsingEncoding: NSUTF8StringEncoding], NULL, NULL) < 0) {   // 打开文件，并生成一个格式上下文对象，用以总览文件操纵逻辑
        if (formatCtx) {
            avformat_free_context(formatCtx);
        }
        return DLDecoderErrorOpenFile;
    }
    
    if (avformat_find_stream_info(formatCtx, NULL) < 0) {
        avformat_close_input(&formatCtx);   // 文件格式上下文对象中 未找到流信息，则关闭上下文
        return DLDecoderErrorStreamInfoNotFound;
    }
    av_dump_format(formatCtx, 0, [path.lastPathComponent cStringUsingEncoding: NSUTF8StringEncoding], false);
    self.formatCtx = formatCtx;
    return DLDecoderErrorNone;
}

- (DLDecoderError) openVideoStream    {
    DLDecoderError errCode = DLDecoderErrorStreamInfoNotFound;
    _videoStream = -1;
    _artworkStream = -1;
    _videoStreams = collectStreams(_formatCtx, AVMEDIA_TYPE_VIDEO);
    for (NSNumber *n in _videoStreams) {
        const NSUInteger iStream = n.integerValue;
        if (0 == (_formatCtx->streams[iStream]->disposition & AV_DISPOSITION_ATTACHED_PIC)) {
            errCode = [self openVideoStream: iStream];
            if (errCode == DLDecoderErrorNone)
                break;
        } else {
            _artworkStream = iStream;
        }
    }
    return errCode;
}

- (DLDecoderError) openVideoStream: (NSInteger) videoStream   {
    if(videoStream < 0 || videoStream >= _formatCtx->nb_streams) {
        return DLDecoderErrorStreamNotFound;
    }
    AVCodecContext *codecCtx = NULL;
    AVCodec *codec = NULL;
    codecCtx = avcodec_alloc_context3(NULL);
    int ret = avcodec_parameters_to_context(codecCtx, _formatCtx->streams[videoStream]->codecpar);
    if (ret < 0) {
        return DLDecoderErrorFillCodecContext;
    }
    if (codecCtx && (codecCtx->pix_fmt == AV_PIX_FMT_YUV420P || codecCtx->pix_fmt == AV_PIX_FMT_YUVJ420P)) {
        self.videoFrameFormat = DLVideoFrameFormatYUV;
    } else {
        self.videoFrameFormat = DLVideoFrameFormatRGB;
    }
    codec = avcodec_find_decoder(codecCtx->codec_id);
    if (!codec) {
        return DLDecoderErrorCodecNotFound;
    }
    if(avcodec_open2(codecCtx, codec, NULL) < 0) {
        return DLDecoderErrorOpenCodec;
    }
    
    self.videoFrame = av_frame_alloc();

    if (!_videoFrame) {
        avcodec_close(codecCtx);
        return DLDecoderErrorAllocateFrame;
    }

    self.videoStream = videoStream;
    self.videoCodecCtx = codecCtx;

    AVStream *st = _formatCtx->streams[_videoStream];
    avStreamFPSTimeBase(st, codecCtx, 0.04, &_fps, &_videoTimeBase); // 获取视频帧率、时间基

    NSLog(@"video codec size: %lu:%lu fps: %.3f tb: %f", (unsigned long)self.frameWidth, (unsigned long)self.frameHeight, self.fps, self.videoTimeBase);
    NSLog(@"video start time %f", st->start_time * _videoTimeBase);
    NSLog(@"video disposition %d", st->disposition);

    return DLDecoderErrorNone;
}

- (DLDecoderError) openAudioStream    {
    DLDecoderError errCode = DLDecoderErrorStreamNotFound;
    self.audioStream = -1;
    self.audioStreams = collectStreams(_formatCtx, AVMEDIA_TYPE_AUDIO);
    for (NSNumber *n in _audioStreams) {
        errCode = [self openAudioStream: n.integerValue];
        if (errCode == DLDecoderErrorNone) {
            break;
        }
    }
    return errCode;
}

- (DLDecoderError) openAudioStream: (NSInteger) audioStream   {
    if(audioStream < 0 || audioStream >= _formatCtx->nb_streams) {
        return DLDecoderErrorStreamNotFound;
    }
    AVCodecContext *codecCtx = NULL;
    AVCodec *codec = NULL;
    SwrContext *swrContext = NULL;
    codecCtx = avcodec_alloc_context3(NULL);
    int ret = avcodec_parameters_to_context(codecCtx, _formatCtx->streams[audioStream]->codecpar);
    if (ret < 0) {
        return DLDecoderErrorFillCodecContext;
    }
    codec = avcodec_find_decoder(codecCtx->codec_id);
    if (!codec) {
        return DLDecoderErrorCodecNotFound;
    }
    if(avcodec_open2(codecCtx, codec, NULL) < 0) {
        return DLDecoderErrorOpenCodec;
    }
    
    if (!audioCodecIsSupported(codecCtx)) { // 若当前设备不支持 打开的多媒体文件音频格式(采样率、通道数)，则进行重采样
        swrContext = swr_alloc_set_opts(NULL,
                                        av_get_default_channel_layout(_hardwareNumOutputChannels),
                                        AV_SAMPLE_FMT_S16,
                                        _hardwareSamplingRate,
                                        av_get_default_channel_layout(codecCtx->channels),
                                        codecCtx->sample_fmt,
                                        codecCtx->sample_rate,
                                        0,
                                        NULL);
        if (!swrContext ||  swr_init(swrContext)) {
            if (swrContext) {
                swr_free(&swrContext);
            }
            avcodec_close(codecCtx);
            return DLDecoderErroReSampler;
        }
    }
    
    self.audioFrame = av_frame_alloc(); // 分配音频帧内存
    
    if (!_audioFrame) { // 音频帧内存分配失败处理：
        if (swrContext)
            swr_free(&swrContext);  // 释放重采样上下文
        avcodec_close(codecCtx);    // 关闭解码上下文
        return DLDecoderErrorAllocateFrame;   // 返回预设的错误码
    }
    
    self.audioStream = audioStream;
    self.audioCodecCtx = codecCtx;
    self.swrContext = swrContext;
    
    AVStream *st = _formatCtx->streams[_audioStream];
    avStreamFPSTimeBase(st, codecCtx, 0.025, 0, &_audioTimeBase);  // 获取音频流时间基
    
    NSLog(@"audio codec smr: %.d fmt: %d chn: %d tb: %f %@",
          _audioCodecCtx->sample_rate,
          _audioCodecCtx->sample_fmt,
          _audioCodecCtx->channels,
          _audioTimeBase,
          _swrContext ? @"resample" : @"");
    
    return DLDecoderErrorNone;
}

- (DLDecoderError) openSubtitleStream: (NSInteger) subtitleStream {
    if(subtitleStream < 0 || subtitleStream >= _formatCtx->nb_streams) {
        return DLDecoderErrorStreamNotFound;
    }
    AVCodecContext *codecCtx = NULL;
    AVCodec *codec = NULL;
    codecCtx = avcodec_alloc_context3(NULL);
    int ret = avcodec_parameters_to_context(codecCtx, _formatCtx->streams[subtitleStream]->codecpar);
    if (ret < 0) {
        return DLDecoderErrorFillCodecContext;
    }
    codec = avcodec_find_decoder(codecCtx->codec_id);
    if (!codec) {
        return DLDecoderErrorCodecNotFound;
    }
    if(avcodec_open2(codecCtx, codec, NULL) < 0) {
        return DLDecoderErrorOpenCodec;
    }
    
    const AVCodecDescriptor *codecDesc = avcodec_descriptor_get(codecCtx->codec_id);
    if (codecDesc && (codecDesc->props & AV_CODEC_PROP_BITMAP_SUB)) {
        // Only text based subtitles supported
        return DLDecoderErroUnsupported;
    }
    if (avcodec_open2(codecCtx, codec, NULL) < 0)
        return DLDecoderErrorOpenCodec;
    self.subtitleStream = subtitleStream;
    self.subtitleCodecCtx = codecCtx;
    NSLog(@"subtitle codec: '%s' mode: %d enc: %s",
          codecDesc->name,
          codecCtx->sub_charenc_mode,
          codecCtx->sub_charenc);
    self.subtitleASSEvents = -1;
    if (codecCtx->subtitle_header_size) {
        NSString *s = [[NSString alloc] initWithBytes:codecCtx->subtitle_header
                                               length:codecCtx->subtitle_header_size
                                             encoding:NSASCIIStringEncoding];
        if (s.length) {
            NSArray *fields = [DLAVFrameSubtitleaASSParser parseEvents:s];
            if (fields.count && [fields.lastObject isEqualToString:@"Text"]) {
                self.subtitleASSEvents = fields.count;
                NSLog(@"subtitle ass events: %@", [fields componentsJoinedByString:@","]);
            }
        }
    }
    return DLDecoderErrorNone;
}

- (void) closeVideoStream   {
    self.videoStream = -1;
    [self closeScaler];
    if (_videoFrame) {
        av_free(_videoFrame);
        self.videoFrame = NULL;
    }
    if (_videoCodecCtx) {
        avcodec_close(_videoCodecCtx);
        self.videoCodecCtx = NULL;
    }
}

- (void) closeAudioStream   {
    self.audioStream = -1;
    if (_swrBuffer) {
        free(_swrBuffer);
        self.swrBuffer = NULL;
        self.swrBufferSize = 0;
    }
    if (_swrContext) {
        swr_free(&_swrContext);
        self.swrContext = NULL;
    }
    if (_audioFrame) {
        av_free(_audioFrame);
        self.audioFrame = NULL;
    }
    if (_audioCodecCtx) {
        avcodec_close(_audioCodecCtx);
        self.audioCodecCtx = NULL;
    }
}

- (void) closeSubtitleStream    {
    self.subtitleStream = -1;
    if (_subtitleCodecCtx) {
        avcodec_close(_subtitleCodecCtx);
        self.subtitleCodecCtx = NULL;
    }
}

- (void) closeScaler    {   // 关闭视频裁剪上下文
    if (_swsContext) {
        sws_freeContext(_swsContext);
        self.swsContext = NULL;
    }
    if (_pictureValid) {
        avpicture_free(&_picture);  // 释放裁剪缓存
        self.pictureValid = NO;
    }
}

- (BOOL) setupScaler    {   // 设置裁剪上下文
    [self closeScaler];
    assert(_videoCodecCtx != NULL);
    
    self.pictureValid = avpicture_alloc(&_picture,
                                    AV_PIX_FMT_RGB24,
                                    _videoCodecCtx->width,
                                    _videoCodecCtx->height) == 0;   // 分配采集缓存
    if (!_pictureValid) {
         return NO;
    }
    self.swsContext = sws_getCachedContext(_swsContext,
                                       _videoCodecCtx->width,
                                       _videoCodecCtx->height,
                                       _videoCodecCtx->pix_fmt,
                                       _videoCodecCtx->width,
                                       _videoCodecCtx->height,
                                       AV_PIX_FMT_RGB24,
                                       SWS_FAST_BILINEAR,
                                       NULL, NULL, NULL);
    return _swsContext != NULL;
}

- (id<DLVideoFrameProtocol>) handleVideoFrame {   // 视频解码后处理工作流
    if (!_videoFrame->data[0])  {
        return nil;
    }
    // 把解码出来的 AVFrame 对象，转换成自定义视频帧
    id<DLVideoFrameProtocol> frame;
    if (_videoFrameFormat == DLVideoFrameFormatYUV) {   // yuv帧转换过程
        id<DLVideoFrameYUVProtocol> yuvFrame = (id<DLVideoFrameYUVProtocol>)[DLAVFrame videoFrameWithFormat:DLVideoFrameFormatYUV];
        yuvFrame.luma = copyFrameData(_videoFrame->data[0],
                                      _videoFrame->linesize[0],
                                      _videoCodecCtx->width,
                                      _videoCodecCtx->height);
        
        yuvFrame.chromaB = copyFrameData(_videoFrame->data[1],
                                         _videoFrame->linesize[1],
                                         _videoCodecCtx->width / 2,
                                         _videoCodecCtx->height / 2);
        
        yuvFrame.chromaR = copyFrameData(_videoFrame->data[2],
                                         _videoFrame->linesize[2],
                                         _videoCodecCtx->width / 2,
                                         _videoCodecCtx->height / 2);
        frame = yuvFrame;
    } else {    // rgb帧转换过程
        if (!_swsContext && ![self setupScaler]) {
            NSLog(@"Fail setup video scaler");
            return nil;
        }
        sws_scale(_swsContext,
                  (const uint8_t **)_videoFrame->data,
                  _videoFrame->linesize,
                  0,
                  _videoCodecCtx->height,
                  _picture.data,
                  _picture.linesize);
        
        id<DLVideoFrameRGBProtocol> rgbFrame = (id<DLVideoFrameRGBProtocol>)[DLAVFrame videoFrameWithFormat:DLVideoFrameFormatRGB];
        rgbFrame.linesize = _picture.linesize[0];
        rgbFrame.rgb = [NSData dataWithBytes:_picture.data[0]
                                      length:rgbFrame.linesize * _videoCodecCtx->height];
        frame = rgbFrame;
    }
    
    frame.width = _videoCodecCtx->width;
    frame.height = _videoCodecCtx->height;
    frame.position = _videoFrame->best_effort_timestamp * _videoTimeBase;
    const int64_t frameDuration = _videoFrame->pkt_duration;
    
    if (frameDuration) {
        frame.duration = frameDuration * _videoTimeBase;
        frame.duration += _videoFrame->repeat_pict * _videoTimeBase * 0.5;
        if (_videoFrame->repeat_pict > 0) {
            NSLog(@"_videoFrame.repeat_pict %d", _videoFrame->repeat_pict);
        }
    } else {
        frame.duration = 1.0 / _fps;
    }
#if 0
    NSLog(@"VFD: %.4f %.4f | %lld ",
            frame.position,
            frame.duration,
            av_frame_get_pkt_pos(_videoFrame));
#endif
    return frame;
}

- (id<DLAudioFrameProtocol>) handleAudioFrame {   // 音频解码后处理工作流 ???
    if (!_audioFrame->data[0])  {
        return nil;
    }
    const NSUInteger numChannels = _hardwareNumOutputChannels;
    NSInteger numFrames;
    void * audioData;
    if (_swrContext) {
        const NSUInteger ratio = MAX(1, _hardwareSamplingRate / _audioCodecCtx->sample_rate) *
        MAX(1, _hardwareNumOutputChannels / _audioCodecCtx->channels) * 2;
        
        const int bufSize = av_samples_get_buffer_size(NULL,
                                                       _hardwareNumOutputChannels,
                                                       (int)(_audioFrame->nb_samples * ratio),
                                                       AV_SAMPLE_FMT_S16,
                                                       1);
        
        if (!_swrBuffer || _swrBufferSize < bufSize) {
            _swrBufferSize = bufSize;
            self.swrBuffer = realloc(_swrBuffer, _swrBufferSize);
        }
        
        Byte *outbuf[2] = { _swrBuffer, 0 };
        
        numFrames = swr_convert(_swrContext,
                                outbuf,
                                (int)(_audioFrame->nb_samples * ratio),
                                (const uint8_t **)_audioFrame->data,
                                _audioFrame->nb_samples);
        
        if (numFrames < 0) {
            NSLog(@"fail resample audio");
            return nil;
        }
        
        audioData = _swrBuffer;
    } else {
        if (_audioCodecCtx->sample_fmt != AV_SAMPLE_FMT_S16) {
            NSAssert(false, @"bucheck, audio format is invalid");
            return nil;
        }
        audioData = _audioFrame->data[0];
        numFrames = _audioFrame->nb_samples;
    }
    
    const NSUInteger numElements = numFrames * numChannels;
    NSMutableData *data = [NSMutableData dataWithLength:numElements * sizeof(float)];
    
    float scale = 1.0 / (float)INT16_MAX ;
    vDSP_vflt16((SInt16 *)audioData, 1, data.mutableBytes, 1, numElements);
    vDSP_vsmul(data.mutableBytes, 1, &scale, data.mutableBytes, 1, numElements);
    
    id<DLAudioFrameProtocol> frame = (id<DLAudioFrameProtocol>)[DLAVFrame frameWithType:DLAVFrameTypeAudio];
    frame.position = _audioFrame->best_effort_timestamp * _audioTimeBase;
    frame.duration = _audioFrame->pkt_duration * _audioTimeBase;
    frame.samples = data;
    
    if (frame.duration == 0) {
        NSAssert(_hardwareSamplingRate > 0, @"_hardwareSamplingRate error");
        frame.duration = frame.samples.length / (sizeof(float) * numChannels * _hardwareSamplingRate);
    }
    
#if 0
    NSLog(@"AFD: %.4f %.4f | %.4f ",
            frame.position,
            frame.duration,
            frame.samples.length / (8.0 * 44100.0));
#endif
    
    return frame;
}

- (id<DLSubtitleFrameProtocol>) handleSubtitle: (AVSubtitle *)pSubtitle   {
    NSMutableString *ms = [NSMutableString string];
    for (NSUInteger i = 0; i < pSubtitle->num_rects; ++i) {
        AVSubtitleRect *rect = pSubtitle->rects[i];
        if (rect) {
            if (rect->text) { // rect->type == SUBTITLE_TEXT
                NSString *s = [NSString stringWithUTF8String:rect->text];
                if (s.length) {
                    [ms appendString:s];
                }
            } else if (rect->ass && _subtitleASSEvents != -1) {
                NSString *s = [NSString stringWithUTF8String:rect->ass];
                if (s.length) {
                    NSArray *fields = [DLAVFrameSubtitleaASSParser parseDialogue:s numFields:_subtitleASSEvents];
                    if (fields.count && [fields.lastObject length]) {
                        s = [DLAVFrameSubtitleaASSParser removeCommandsFromEventText: fields.lastObject];
                        if (s.length) [ms appendString:s];
                    }
                }
            }
        }
    }
    
    if (!ms.length) {
        return nil;
    }
    id<DLSubtitleFrameProtocol> frame = (id<DLSubtitleFrameProtocol>)[DLAVFrame frameWithType:DLAVFrameTypeSubtitle];
    frame.text = [ms copy];
    frame.position = pSubtitle->pts / AV_TIME_BASE + pSubtitle->start_display_time;
    frame.duration = (CGFloat)(pSubtitle->end_display_time - pSubtitle->start_display_time) / 1000.f;
    
#if 0
    NSLog(@"SUB: %.4f %.4f | %@",
             frame.position,
             frame.duration,
             frame.text);
#endif
    
    return frame;
}

@end
