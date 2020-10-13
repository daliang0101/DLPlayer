//
//  DlDecoderErrorDefines.h
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/21.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DlDecoderErrorDefines_h
#define DlDecoderErrorDefines_h

typedef NS_ENUM(NSUInteger, DLDecoderError) {
    DLDecoderErrorNone,
    DLDecoderErrorFillCodecContext,
    DLDecoderErrorOpenFile,
    DLDecoderErrorStreamInfoNotFound,
    DLDecoderErrorStreamNotFound,
    DLDecoderErrorCodecNotFound,
    DLDecoderErrorOpenCodec,
    DLDecoderErrorAllocateFrame,
    DLDecoderErroSetupScaler,
    DLDecoderErroReSampler,
    DLDecoderErroUnsupported,
};

NSString * DLDecoderErrorDomain = @"DL.DecoderError.Domain";
static void FFLog(void* context, int level, const char* format, va_list args);

static NSError * kxmovieError (NSInteger code, id info)
{
    NSDictionary *userInfo = nil;
    
    if ([info isKindOfClass: [NSDictionary class]]) {
        
        userInfo = info;
        
    } else if ([info isKindOfClass: [NSString class]]) {
        
        userInfo = @{ NSLocalizedDescriptionKey : info };
    }
    
    return [NSError errorWithDomain:DLDecoderErrorDomain
                               code:code
                           userInfo:userInfo];
}

static NSString * errorMessage (DLDecoderError errorCode)
{
    switch (errorCode) {
        case DLDecoderErrorNone:
            return @"";
            
        case DLDecoderErrorFillCodecContext:
            return NSLocalizedString(@"Fill codec codecontext error", nil);
            
        case DLDecoderErrorOpenFile:
            return NSLocalizedString(@"Unable to open file", nil);
            
        case DLDecoderErrorStreamInfoNotFound:
            return NSLocalizedString(@"Unable to find stream information", nil);
            
        case DLDecoderErrorStreamNotFound:
            return NSLocalizedString(@"Unable to find stream", nil);
            
        case DLDecoderErrorCodecNotFound:
            return NSLocalizedString(@"Unable to find codec", nil);
            
        case DLDecoderErrorOpenCodec:
            return NSLocalizedString(@"Unable to open codec", nil);
            
        case DLDecoderErrorAllocateFrame:
            return NSLocalizedString(@"Unable to allocate frame", nil);
            
        case DLDecoderErroSetupScaler:
            return NSLocalizedString(@"Unable to setup scaler", nil);
            
        case DLDecoderErroReSampler:
            return NSLocalizedString(@"Unable to setup resampler", nil);
            
        case DLDecoderErroUnsupported:
            return NSLocalizedString(@"The ability is not supported", nil);
    }
}

#endif /* DlDecoderErrorDefines_h */
