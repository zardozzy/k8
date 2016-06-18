//
//  VVCfft.m
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

#import "VVCfft.h"
#import "fftw3.h"

@implementation VVCfft {
    fftw_complex *fftOut;
    fftw_complex *fftIn;
    fftw_plan vvcPlan;
    
    double iFFTvalue;
    double qFFTvalue;
    
    BOOL setupOK;
}


- (instancetype)init {
    // This instance must be created with the initWithFFTsize initializer
    return nil;
}

- (instancetype)initWithFFTsize:(uint16_t)size {
    self = [super init];
    
    if (self) {
        setupOK = false;
        
        _fftsize = size;
        
        [self setupFFT];
        
        if (setupOK) {
            return self;
        } else {
            return nil;
        }
    }
    
    return nil;
}

- (void)calcFFT {
    // Calculate FFT using current values
    if (setupOK) {
        fftw_execute(vvcPlan);
        //NSLog(@"Executed vvcPlan");
    }
}

- (void)setupFFT {
    // Setup fftw3
    fftOut = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * _fftsize);
    fftIn = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * _fftsize);
    vvcPlan = fftw_plan_dft_1d(_fftsize, fftIn, fftOut, FFTW_FORWARD, FFTW_MEASURE);
    setupOK = YES; // Need to check fftw_malloc really to set this as ok!
}

- (void)stopFFT {
    // Cleanup FFT
    NSLog(@"Stop FFT called");
    fftw_free(fftOut);
    fftw_free(fftIn);
}

- (double)getIfft:(uint16_t)arrayNum {
    // Get I FFT value in array
    if (setupOK) {
        if (arrayNum < _fftsize) {
            iFFTvalue = fftOut[arrayNum][0];
            return iFFTvalue;
        } else {
            return 0;
        }
    }
    return 0;
}

- (double)getQfft:(uint16_t)arrayNum {
    // Get Q FFT value in array
    if (setupOK) {
        if (arrayNum < _fftsize) {
            qFFTvalue = fftOut[arrayNum][1];
            return qFFTvalue;
        } else {
            return 0;
        }
    }
    return 0;
}

- (void)setIfft:(uint16_t)arrayNum iValue:(float)value {
    // Set I value in array
    if (arrayNum < _fftsize) {
        // Set it
        fftIn[arrayNum][0] = value;
    }
}

- (void)setQfft:(uint16_t)arrayNum qValue:(float)value {
    // Set Q value in array
    if (arrayNum < _fftsize) {
        // Set it
        fftIn[arrayNum][1] = value;
    }
    
}

@end
