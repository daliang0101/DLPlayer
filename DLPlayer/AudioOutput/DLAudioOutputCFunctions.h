//
//  DLAudioOutputCFunctions.h
//  DLPlayer
//
//  Created by Daliang on 2020/9/21.
//  Copyright © 2020 Daliang. All rights reserved.
//

#ifndef DLAudioOutputCFunctions_h
#define DLAudioOutputCFunctions_h

// Debug: dump the current frame data. Limited to 20 samples.
#define dumpAudioSamples(prefix, dataBuffer, samplePrintFormat, sampleCount, channelCount) \
{ \
NSMutableString *dump = [NSMutableString stringWithFormat:prefix]; \
for (int i = 0; i < MIN(MAX_SAMPLE_DUMPED, sampleCount); i++) \
{ \
for (int j = 0; j < channelCount; j++) \
{ \
[dump appendFormat:samplePrintFormat, dataBuffer[j + i * channelCount]]; \
} \
[dump appendFormat:@"\n"]; \
} \
NSLog(@"%@", dump); \
}

#define dumpAudioSamplesNonInterleaved(prefix, dataBuffer, samplePrintFormat, sampleCount, channelCount) \
{ \
NSMutableString *dump = [NSMutableString stringWithFormat:prefix]; \
for (int i = 0; i < MIN(MAX_SAMPLE_DUMPED, sampleCount); i++) \
{ \
for (int j = 0; j < channelCount; j++) \
{ \
[dump appendFormat:samplePrintFormat, dataBuffer[j][i]]; \
} \
[dump appendFormat:@"\n"]; \
} \
NSLog(@"%@", dump); \
}

static void sessionPropertyListener(void *                  inClientData,
                                    AudioSessionPropertyID  inID,
                                    UInt32                  inDataSize,
                                    const void *            inData)
{
    id<DLAudioOutputPrivateProtocol> sm = (__bridge id<DLAudioOutputPrivateProtocol>)inClientData;
    
    if (inID == kAudioSessionProperty_AudioRouteChange) {
        if ([sm checkAudioRoute]) {
            [sm checkSessionProperties];
        }
    } else if (inID == kAudioSessionProperty_CurrentHardwareOutputVolume) {
        if (inData && inDataSize == 4) {
            sm.outputVolume = *(float *)inData;
        }
    }
}

static void sessionInterruptionListener(void *inClientData, UInt32 inInterruption)
{
    id<DLAudioOutputPrivateProtocol, DLAudioOutputProtocol> sm = (__bridge id<DLAudioOutputPrivateProtocol, DLAudioOutputProtocol>)inClientData;
    
    if (inInterruption == kAudioSessionBeginInterruption) {
        NSLog(@"Begin interuption");
        sm.playAfterSessionEndInterruption = sm.playing;
        [sm pause];
        
    } else if (inInterruption == kAudioSessionEndInterruption) {
        NSLog(@"End interuption");
        if (sm.playAfterSessionEndInterruption) {
            sm.playAfterSessionEndInterruption = NO;
            [sm play];
        }
    }
}

static OSStatus renderCallback (void                        *inRefCon,
                                AudioUnitRenderActionFlags    * ioActionFlags,
                                const AudioTimeStamp         * inTimeStamp,
                                UInt32                        inOutputBusNumber,
                                UInt32                        inNumberFrames,
                                AudioBufferList                * ioData)
{
    id<DLAudioOutputPrivateProtocol> sm = (__bridge id<DLAudioOutputPrivateProtocol>)inRefCon;
    return [sm renderFrames:inNumberFrames ioData:ioData];
}

static BOOL checkError(OSStatus error, const char *operation)
{
    if (error == noErr) {
        return NO;
    }
    
    char str[20] = {0};
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else {
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    }
    
    NSLog(@"Error: %s (%s)\n", operation, str);
    
    //exit(1);
    
    return YES;
}

#endif /* DLAudioOutputCFunctions_h */
