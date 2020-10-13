//
//  DLAudioOutputAudioUnit.m
//  DLPlayer
//
//  Created by Daliang Cao on 2020/9/20.
//  Copyright © 2020 Daliang. All rights reserved.
//

#import "DLAudioOutputAudioUnit.h"
#import "TargetConditionals.h"
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>
#import "DLAudioOutputPrivateProtocol.h"
#import "DLAudioOutputCFunctions.h"

#define MAX_CHAN          2
#define MAX_FRAME_SIZE    4096
#define MAX_SAMPLE_DUMPED 5

@interface DLAudioOutputAudioUnit () <DLAudioOutputPrivateProtocol>

@end

@implementation DLAudioOutputAudioUnit

AUDIO_PROPERTIES_COMPILE_SETUP

#pragma mark - Init

- (instancetype)init {
    self = [super init];
    if (self) {
        _outData = (float *)calloc(MAX_FRAME_SIZE*MAX_CHAN, sizeof(float));
        _outputVolume = 0.5;
        _isOn = YES;
    }
    return self;
}

- (void)dealloc {
    if (_outData) {
        free(_outData);
        _outData = NULL;
    }
}

#pragma mark - DLAudioOutputProtocol's public methods

- (BOOL)activateAudioSession {
    if (!_activated) {
        if (!_initialized) {
            if (checkError(AudioSessionInitialize(NULL,
                                                  kCFRunLoopDefaultMode,
                                                  sessionInterruptionListener,
                                                  (__bridge void *)(self)),
                           "Couldn't initialize audio session"))
            {
                return NO;
            }
            self.initialized = YES;
        }
        if ([self checkAudioRoute] && [self setupAudio]) {
            self.activated = YES;
        }
    }
    return _activated;
}

- (void)deactivateAudioSession {
    if (_activated) {
        [self pause];
        checkError(AudioUnitUninitialize(_audioUnit), "Couldn't uninitialize the audio unit");
        
        /*
         fails with error (-10851) ?
         
         checkError(AudioUnitSetProperty(_audioUnit,
         kAudioUnitProperty_SetRenderCallback,
         kAudioUnitScope_Input,
         0,
         NULL,
         0),
         "Couldn't clear the render callback on the audio unit");
         */
        
        checkError(AudioComponentInstanceDispose(_audioUnit), "Couldn't dispose the output audio unit");
        
        checkError(AudioSessionSetActive(NO), "Couldn't deactivate the audio session");
        
        
    checkError(AudioSessionRemovePropertyListenerWithUserData (kAudioSessionProperty_AudioRouteChange,
         sessionPropertyListener,
         (__bridge void *)(self)),
         "Couldn't remove audio session property listener");
        
    checkError(AudioSessionRemovePropertyListenerWithUserData (kAudioSessionProperty_CurrentHardwareOutputVolume,
         sessionPropertyListener,
         (__bridge void *)(self)),
         "Couldn't remove audio session property listener");
        
        _activated = NO;
    }
}

- (void)pause {
    self.isOn = NO;
    if (_playing) {
        _playing = checkError(AudioOutputUnitStop(_audioUnit), "Couldn't stop the output unit");
    }
}

- (BOOL)play {
    self.isOn = YES;
    NSLog(@"audio device smr: %d fmt: %d chn: %d",
          (int)self.samplingRate,
          (int)self.numBytesPerSample,
          (int)self.numOutputChannels);
    
    if (!_playing) {
        if ([self activateAudioSession]) {
            _playing = !checkError(AudioOutputUnitStart(_audioUnit), "Couldn't start the output unit");
        }
    }
    return _playing;
}

- (void)stop {
    [self deactivateAudioSession];
}

#pragma mark - DLAudioOutputProtocol's private methods

- (BOOL)checkAudioRoute {
    UInt32 propertySize = sizeof(CFStringRef);
    CFStringRef route;
    if (checkError(AudioSessionGetProperty(kAudioSessionProperty_AudioRoute,
                                           &propertySize,
                                           &route),
                   "Couldn't check the audio route")
        )
    {
        return NO;
    }
    
    _audioRoute = CFBridgingRelease(route);
    NSLog(@"AudioRoute: %@", _audioRoute);
    return YES;
}

- (BOOL)checkSessionProperties {
    [self checkAudioRoute];
    
    // Check the number of output channels.
    UInt32 newNumChannels;
    UInt32 size = sizeof(newNumChannels);
    if (checkError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputNumberChannels,
                                           &size,
                                           &newNumChannels),
                   "Checking number of output channels"))
    {
        return NO;
    }
    
    NSLog(@"We've got %u output channels", (unsigned int)newNumChannels);
    
    // Get the hardware sampling rate. This is settable, but here we're only reading.
    size = sizeof(_samplingRate);
    if (checkError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,
                                           &size,
                                           &_samplingRate),
                   "Checking hardware sampling rate"))
    {
        return NO;
    }
    
    NSLog(@"Current sampling rate: %f", _samplingRate);
    
    size = sizeof(_outputVolume);
    if (checkError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputVolume,
                                           &size,
                                           &_outputVolume),
                   "Checking current hardware output volume"))
    {
        return NO;
    }
    
    NSLog(@"Current output volume: %f", _outputVolume);
    
    return YES;
}

- (BOOL)renderFrames:(UInt32)numFrames ioData:(AudioBufferList *)ioData {
    for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
        memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
    }
    
    if (_playing && _fillDataBlock && _isOn) {
        
        // Collect data to render from the callbacks
        _fillDataBlock(_outData, numFrames, _numOutputChannels);
        
        // Put the rendered data into the output buffer
        if (_numBytesPerSample == 4) // then we've already got floats
        {
            float zero = 0.0;
            
            for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
                
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                
                for (int iChannel = 0; iChannel < thisNumChannels; ++iChannel) {
                    vDSP_vsadd(_outData+iChannel, _numOutputChannels, &zero, (float *)ioData->mBuffers[iBuffer].mData, thisNumChannels, numFrames);
                }
            }
        }
        else if (_numBytesPerSample == 2) // then we need to convert SInt16 -> Float (and also scale)
        {
//            dumpAudioSamples(@"Audio frames decoded by FFmpeg:\n",
//                                         _outData, @"% 12.4f ", numFrames, _numOutputChannels);
            
            float scale = (float)INT16_MAX;
            vDSP_vsmul(_outData, 1, &scale, _outData, 1, numFrames*_numOutputChannels);
            
#ifdef DUMP_AUDIO_DATA
            NSLog(@"Buffer %u - Output Channels %u - Samples %u",
                   (uint)ioData->mNumberBuffers,
                   (uint)ioData->mBuffers[0].mNumberChannels,
                   (uint)numFrames);
#endif
            
            for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
                
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                
                for (int iChannel = 0; iChannel < thisNumChannels; ++iChannel) {
                    vDSP_vfix16(_outData+iChannel, _numOutputChannels, (SInt16 *)ioData->mBuffers[iBuffer].mData+iChannel, thisNumChannels, numFrames);
                }
#ifdef DUMP_AUDIO_DATA
                dumpAudioSamples(@"Audio frames decoded by FFmpeg and reformatted:\n",
                                 ((SInt16 *)ioData->mBuffers[iBuffer].mData),
                                 @"% 8d ", numFrames, thisNumChannels);
#endif
            }
            
        }
    }
    
    return noErr;
}

- (BOOL)setupAudio {
    // --- Audio Session Setup ---
    
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    //UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
    if (checkError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                                           sizeof(sessionCategory),
                                           &sessionCategory),
                   "Couldn't set audio category"))
    {
        return NO;
    }
    
    
    if (checkError(AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange,
                                                   sessionPropertyListener,
                                                   (__bridge void *)(self)),
                   "Couldn't add audio session property listener"))
    {
        
    }
    
    if (checkError(AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume,
                                                   sessionPropertyListener,
                                                   (__bridge void *)(self)),
                   "Couldn't add audio session property listener"))
    {
        
    }
    
#if !TARGET_IPHONE_SIMULATOR
    Float32 preferredBufferSize = 0.0232;
    if (checkError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration,
                                           sizeof(preferredBufferSize),
                                           &preferredBufferSize),
                   "Couldn't set the preferred buffer duration")) {
    }
#endif
    
    if (checkError(AudioSessionSetActive(YES), "Couldn't activate the audio session")) {
        return NO;
    }
    
    [self checkSessionProperties];
    
    // ----- Audio Unit Setup -----
    
    AudioComponentDescription description = {0};
    description.componentType = kAudioUnitType_Output;
    description.componentSubType = kAudioUnitSubType_RemoteIO;
    description.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AudioComponent component = AudioComponentFindNext(NULL, &description);
    if (checkError(AudioComponentInstanceNew(component, &_audioUnit),
                   "Couldn't create the output audio unit"))
        return NO;
    
    UInt32 size;
    
    // Check the output stream format
    size = sizeof(AudioStreamBasicDescription);
    if (checkError(AudioUnitGetProperty(_audioUnit,
                                        kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Input,
                                        0,
                                        &_outputFormat,
                                        &size),
                   "Couldn't get the hardware output stream format"))
    {
        return NO;
    }
    
    
    _outputFormat.mSampleRate = _samplingRate;
    if (checkError(AudioUnitSetProperty(_audioUnit,
                                        kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Input,
                                        0,
                                        &_outputFormat,
                                        size),
                   "Couldn't set the hardware output stream format")) {
        // just warning
    }
    
    _numBytesPerSample = _outputFormat.mBitsPerChannel / 8;
    _numOutputChannels = _outputFormat.mChannelsPerFrame;
    
    NSLog(@"Current output bytes per sample: %u", (unsigned int)_numBytesPerSample);
    NSLog(@"Current output num channels: %u", (unsigned int)_numOutputChannels);
    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = renderCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    
    if (checkError(AudioUnitSetProperty(_audioUnit,
                                        kAudioUnitProperty_SetRenderCallback,
                                        kAudioUnitScope_Input,
                                        0,
                                        &callbackStruct,
                                        sizeof(callbackStruct)),
                   "Couldn't set the render callback on the audio unit"))
    {
        return NO;
    }
    
    if (checkError(AudioUnitInitialize(_audioUnit), "Couldn't initialize the audio unit")) {
        return NO;
    }
    
    return YES;
}

@end
