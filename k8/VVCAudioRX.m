//
//  VVCAudioRX.m
//  k8
//
//  Created by Matthew Walker on 02/10/2015.
//  Copyright © 2015 Matthew Walker. All rights reserved.
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#import "VVCAudioRX.h"
#import "AudioToolbox/AudioQueue.h"
#import "AudioToolbox/AudioFile.h"

@implementation VVCAudioRX {
    uint16_t sampleNumber;
    
    int16_t sample;
    
    uint8_t frameByteMultiplier;
    uint8_t totalSampleShift;
    uint8_t leftTotalByteShift;
    uint8_t rightTotalByteShift;
    
    float hanningMultiplier;
    
    float *iSignalValue;
    float *qSignalValue;
    
    bool setupOK;
}

static const uint8_t kNumberBuffers = 3;

uint8_t *capturedSample;

typedef struct AQRecorderState {
    AudioStreamBasicDescription  mDataFormat;
    AudioQueueRef                mQueue;
    AudioQueueBufferRef          mBuffers[kNumberBuffers];
    AudioFileID                  mAudioFile;
    uint32_t                     bufferByteSize;
    int64_t                      mCurrentPacket;
    bool                         mIsRunning;
} AQRecorderState ;

AQRecorderState aqData;

static void HandleInputBuffer (
                               void                                 *aqData,
                               AudioQueueRef                        inAQ,
                               AudioQueueBufferRef                  inBuffer,
                               const AudioTimeStamp                 *inStartTime,
                               uint32_t                             inNumPackets,
                               const AudioStreamPacketDescription   *inPacketDesc
                               ) {
    AQRecorderState *pAqData = (AQRecorderState *) aqData;
    
    if (inNumPackets == 0 && pAqData->mDataFormat.mBytesPerPacket != 0) inNumPackets = inBuffer->mAudioDataByteSize / pAqData->mDataFormat.mBytesPerPacket;
    
    if (pAqData->mIsRunning == 0)
        return;
    
    capturedSample = inBuffer->mAudioData;
    
    AudioQueueEnqueueBuffer (pAqData->mQueue, inBuffer, 0, NULL);
}


- (instancetype)init {
    // This instance must be created with the initWithFFTsize initializer
    return nil;
}

- (instancetype)initWithSetup:(uint16_t)size sampleRate:(uint32_t)rate {
    self = [super init];
    
    if (self) {
        setupOK = false;
        
        _fftsize = size;
        _samplingFrequency = rate;
        _leftSampleShift = 0;
        _rightSampleShift = 0;
        _swapIQ = false;
        
        [self setupAQ];
        
        if (setupOK) {
            return self;
        } else {
            return nil;
        }
    }
    
    return nil;
}

- (void)setupAQ {
    frameByteMultiplier = 4;
    
    leftTotalByteShift = _leftSampleShift * frameByteMultiplier;
    rightTotalByteShift = _rightSampleShift * frameByteMultiplier;
    totalSampleShift = _leftSampleShift + _rightSampleShift;
    
    capturedSample = (uint8_t*) malloc(sizeof(uint8_t) * (_fftsize + totalSampleShift) * frameByteMultiplier);
    
    iSignalValue = (float*) malloc(sizeof(float) * _fftsize);
    qSignalValue = (float*) malloc(sizeof(float) * _fftsize);
    
    aqData.mDataFormat.mFormatID = kAudioFormatLinearPCM;
    aqData.mDataFormat.mSampleRate = 48000.0;
    aqData.mDataFormat.mChannelsPerFrame = 2; // Stereo
    aqData.mDataFormat.mBitsPerChannel = 16;
    aqData.mDataFormat.mBytesPerPacket = aqData.mDataFormat.mBytesPerFrame * sizeof(int16_t);
    aqData.mDataFormat.mFramesPerPacket = 1;
    aqData.bufferByteSize = (_fftsize + totalSampleShift) * frameByteMultiplier; // Obtain more samples
                                                                                 // so we can sample shift
    
    aqData.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    
    AudioQueueNewInput(&aqData.mDataFormat, HandleInputBuffer, &aqData, NULL, kCFRunLoopCommonModes, 0, &aqData.mQueue);
    
    // Initialize the recording buffers
    for (uint32_t i = 0; i < kNumberBuffers; i++) {
        AudioQueueAllocateBuffer(aqData.mQueue, aqData.bufferByteSize, &aqData.mBuffers[i]);
        AudioQueueEnqueueBuffer(aqData.mQueue, aqData.mBuffers[i], 0, NULL);
    }
    
    // Start the Audio Queue
    aqData.mCurrentPacket = 0;
    aqData.mIsRunning = true;
    
    AudioQueueStart(aqData.mQueue, NULL);
    
    setupOK = true; // This needs to be set only if the queue created and started correctly
    
}

- (void)stopAudio {
    NSLog(@"stopAudio called");
    
    AudioQueueDispose(aqData.mQueue, true);
    
    free(iSignalValue);
    free(qSignalValue);
    //free(capturedSample);
}

- (void)updateSample {
    frameByteMultiplier = 4;
    
    leftTotalByteShift = _leftSampleShift * frameByteMultiplier;
    rightTotalByteShift = _rightSampleShift * frameByteMultiplier;
    totalSampleShift = _leftSampleShift + _rightSampleShift;
    
    
    sampleNumber = 0;
    
    // Put 1024 samples in the array
    for (int i = 0; i < _fftsize * frameByteMultiplier; i += frameByteMultiplier) {
        // Apply hanning window algorithm
        hanningMultiplier = 0.5 * (1 - cos(2 * M_PI * sampleNumber / _fftsize - 1));
        
        // Fill Left channel
        sample = 0;
        
        // Below is for little endian
        //sample = capturedSample[i + leftTotalByteShift + 1] << 8;
        //sample = sample | capturedSample[i + leftTotalByteShift];
        
        // Below is for big endian
        sample = capturedSample[i + leftTotalByteShift] << 8;
        sample = sample | capturedSample[i + leftTotalByteShift + 1];
        if (sample != 0) {
            iSignalValue[sampleNumber] = hanningMultiplier * ((float)sample / 32767.0);
        } else {
            iSignalValue[sampleNumber] = 0;
        }
        
        // Fill Right channel
        sample = 0;
        
        // Below is for little endian
        //sample = capturedSample[i + rightTotalByteShift + 3] << 8;
        //sample = sample | capturedSample[i + rightTotalByteShift + 2];
        
        // Below is for big endian
        sample = capturedSample[i + rightTotalByteShift + 2] << 8;
        sample = sample | capturedSample[i + rightTotalByteShift + 3];
        if (sample != 0) {
            qSignalValue[sampleNumber] = hanningMultiplier * ((float)sample / 32767.0);
        } else {
            qSignalValue[sampleNumber] = 0;
        }
        
        // Increment the array index
        sampleNumber++;
    }
}

- (float)getIsample:(uint16_t)arrayNum {
    if (_swapIQ) {
        return qSignalValue[arrayNum];
    } else {
        return iSignalValue[arrayNum];
    }
}

- (float)getQsample:(uint16_t)arrayNum {
    if (_swapIQ) {
        return iSignalValue[arrayNum];
    } else {
        return qSignalValue[arrayNum];
    }
}

@end

