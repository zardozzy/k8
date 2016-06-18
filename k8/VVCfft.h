//
//  VVCfft.h
//  k8
//
//  Created by Matthew Walker on 05/10/2015.
//  Copyright © 2015 Matthew Walker. All rights reserved.
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

@interface VVCfft : NSObject

@property (nonatomic, readonly) uint16_t fftsize;

- (instancetype)initWithFFTsize:(uint16_t)size;

- (void)calcFFT;

- (void)stopFFT;

- (double)getIfft:(uint16_t)arrayNum;

- (double)getQfft:(uint16_t)arrayNum;

- (void)setIfft:(uint16_t)arrayNum iValue:(float)value;

- (void)setQfft:(uint16_t)arrayNum qValue:(float)value;

@end
