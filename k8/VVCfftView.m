//
//  VVCfftView.m
//  k8
//
//  Created by Matthew Walker on 05/10/2015.
//  Copyright © 2015 Matthew Walker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VVCAudioRX.h"
#import "VVCfftView.h"
#import "VVCfft.h"

@implementation VVCfftView {
    VVCAudioRX *audioIQ;
    VVCfft *fft;
    
    uint16_t fftsize;
    
    CGContextRef context;
    CGRect fftRect;
    
    bool overlap, gridlines;
    
    int32_t gridCalibration;
    
    float signalCalibration;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [fft stopFFT];
    [audioIQ stopAudio];
    NSLog(@"fftview notified of termination");
}


+ (void) cleanUp {
    NSLog(@"Cleanup called");
}

- (void) cleanMe {
    [fft stopFFT];
    [audioIQ stopAudio];
}

- (void) awakeFromNib {
    
    overlap = true;
    
    fftsize = 1024;
    
    gridlines = true;
    
    fftRect  = CGRectMake (0, 0, fftsize, 400);
    
    gridCalibration = 4; // 4 is 10dB per division
    signalCalibration = 0.3; // Rough calibration made with Softrock Ensemble & UCA222
    
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
    
    audioIQ = [[VVCAudioRX alloc] initWithSetup:fftsize sampleRate:48000];
    [audioIQ setRightSampleShift:1];
    
    [audioIQ setSwapIQ:true];
    
    fft = [[VVCfft alloc] initWithFFTsize:fftsize];
    
    
    [self performSelectorInBackground:@selector(calcFFT:) withObject:nil];
    
    
}

- (void) calcFFT:(id)unused {
    
    @autoreleasepool {
        
        while (TRUE) {
            if (! overlap) {
                // Refresh IQ samples
                [audioIQ updateSample];
                
                // Send all samples to FFT object
                for (uint16_t i = 0; i < fftsize; i++) {
                    [fft setIfft:i iValue:[audioIQ getIsample:i]];
                    [fft setQfft:i qValue:[audioIQ getQsample:i]];
                }
            } else {
                // Re-use some previous samples
                for (int i = 0; i < 512; i++) {
                    [fft setIfft:i iValue:[audioIQ getIsample:i+512]];
                    [fft setQfft:i qValue:[audioIQ getQsample:i+512]];
                }
                // Refresh IQ samples
                [audioIQ updateSample];
                
                for (int i = 512; i < fftsize; i++) {
                    [fft setIfft:i iValue:[audioIQ getIsample:i]];
                    [fft setQfft:i qValue:[audioIQ getQsample:i]];
                }
                
            }
            // Calculate forward FFT
            [fft calcFFT];
            
            usleep(80000);
            
            [self performSelectorOnMainThread:@selector(drawMeFoo) withObject:nil waitUntilDone:YES];
        }
    }
}

- (void)drawMeFoo {
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    
    double magnitude[fftsize];
    
    // Let's play nice and slow things down on resizing to give the CPU a rest.
    if ([self inLiveResize]) {
        usleep(80000);
    }
    
    context = [[NSGraphicsContext currentContext] graphicsPort];
    
    // Calculate the magnitude for the display
    for (uint16_t i = 0; i < fftsize; i++) {
        magnitude[i] = 0;
        double testI = [fft getIfft:i] * signalCalibration;
        double testQ = [fft getQfft:i] * signalCalibration;
        // Calculate the power magnitude. Apparently this is i2 + q2 / 2 * 50ohms
        magnitude[i] = (((testI * testI) + (testQ * testQ)) / 100);
        //magnitude[i] = 1000000;
        
    }
    
    /*for (int i = 1023; i > 512; i--) {
     if (magnitude[i] != 0) {
     CGContextMoveToPoint(context, i - 512, (10 * log10(magnitude[i])));
     CGContextAddLineToPoint(context, i - 512, 0);
     CGContextStrokePath(context);
     }
     }*/
    
    // The following two for-loops render the FFT display correctly, based on
    // the upper sideband being located from bin 1, through to (fftsize / 2) -1,
    // and lower sideband being located from bin fftsize / 2 through to fftsize - 1.
    // See QEX Software Defined Radio for the Masses Part 1 PDF.
    
    // We check magnitude is not 0, to ensure we don't do a divide by 0!
    // We use log10 to create a LOG display.
    CGContextSetLineWidth(context, 1);
    
    CGContextSetFillColorWithColor(context, [[NSColor blackColor] CGColor]);
    CGContextFillRect (context, fftRect);
    CGContextBeginPath(context);
    
    CGContextSetStrokeColorWithColor(context, [[NSColor redColor] CGColor]);
    
    //CGContextSetBlendMode(context, kCGBlendModeNormal);
    //CGContextScaleCTM(context, 1, 4);
    
    
    for (int i = 1; i < (fftsize / 2); i++) {
        if (magnitude[i] != 0) {
            CGContextMoveToPoint(context, i + (fftsize / 2), (10 * log10(magnitude[i]) * gridCalibration));
            CGContextAddLineToPoint(context, i + (fftsize / 2), 0);
            CGContextStrokePath(context);
        }
    }
    
    for (int i = fftsize / 2; i < fftsize; i++) {
        if (magnitude[i] != 0) {
            CGContextMoveToPoint(context, i - (fftsize / 2), (10 * log10(magnitude[i]) * gridCalibration));
            CGContextAddLineToPoint(context, i - (fftsize / 2), 0);
            CGContextStrokePath(context);
        }
    }
    
    // Draw the grid lines
    if (gridlines) {
        CGContextSetBlendMode(context, kCGBlendModeDifference);
        
        //CGContextScaleCTM(context, 1, 1);
        
        CGContextSetStrokeColorWithColor(context, [[NSColor whiteColor] CGColor]);
        
        CGContextBeginPath(context);
        
        CGContextSetLineWidth(context, 0.4);
        
        for (int i = 0; i < fftsize; i+=64) {
            CGContextMoveToPoint(context, i, 400);
            CGContextAddLineToPoint(context, i, 0);
            CGContextStrokePath(context);
        }
        
        //CGContextSetLineWidth(context, 0.4);
        
        for (int i = 0; i < 400; i+=40) {
            CGContextMoveToPoint(context, fftsize, i);
            CGContextAddLineToPoint(context, 0, i);
            CGContextStrokePath(context);
        }
        
    }
    
}

@end