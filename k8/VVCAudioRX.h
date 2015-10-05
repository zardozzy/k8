//
//  VVCAudioRX.h
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

#import <Foundation/Foundation.h>

@interface VVCAudioRX : NSObject

@property (nonatomic, readonly) uint16_t fftsize;
@property (nonatomic, readonly) uint32_t samplingFrequency;
@property (nonatomic, readwrite) uint8_t leftSampleShift;
@property (nonatomic, readwrite) uint8_t rightSampleShift;
@property (nonatomic, readwrite) bool swapIQ;

- (instancetype)initWithSetup:(uint16_t)size sampleRate:(uint32_t)rate;

- (void)updateSample;

- (void)stopAudio;

- (int32_t)getIsample:(uint16_t)arrayNum;

- (int32_t)getQsample:(uint16_t)arrayNum;

@end