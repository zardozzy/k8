//
//  VVCSoftrockUSBCtrl.m
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
#import "VVCSoftrockUSBCtrl.h"
#import "libusb.h"

#define DG8SAQ_VID 0x16c0
#define DG8SAQ_PID 0x05dc

#define CTRL_IN                 (LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_ENDPOINT_IN)
#define CTRL_OUT                (LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_ENDPOINT_OUT)

@implementation VVCSoftrockUSBCtrl {
    libusb_hotplug_callback_handle callbackHandle;
}

static libusb_context *myContext = NULL;
static libusb_device_handle *devHandle = NULL;

int hotplug_callback(struct libusb_context *ctx, struct libusb_device *dev,
                     libusb_hotplug_event event, void *user_data) {
    struct libusb_device_descriptor desc;
    int rc;
    (void)libusb_get_device_descriptor(dev, &desc);
    if (LIBUSB_HOTPLUG_EVENT_DEVICE_ARRIVED == event) {
        rc = libusb_open(dev, &devHandle);
        if (LIBUSB_SUCCESS != rc) {
            NSLog(@"Could not open USB Softrock device\n");
        }
    } else if (LIBUSB_HOTPLUG_EVENT_DEVICE_LEFT == event) {
        if (devHandle) {
            libusb_close(devHandle);
            devHandle = NULL;
        }
    } else {
        NSLog(@"Unhandled USB event %d\n", event);
    }
    return 0;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        if ([self openSoftrock]) {
            return self;
        } else {
            return nil;
        }
    }
    return nil;
}

- (NSString*)firmwareRevision {
    if (devHandle) {
        // Return firmware revision
        
        int r;
        uint16_t iFirmware;
        
        r = libusb_control_transfer(devHandle, CTRL_IN, 0x00, 0x0e00, 0, (unsigned char *)&iFirmware, sizeof(iFirmware), 500);
        
        if (r > 0) {
            if ((iFirmware & 0xFF) > 0) { // Is there a minor number?
                // Yes minor number, so construct NSString with both major & minor numbers
                return [NSString stringWithFormat:@"%u.%u", iFirmware >> 8, iFirmware & 0xFF];
            } else // Construct NSString with just major number
                return [NSString stringWithFormat:@"%u", iFirmware];
        }
        
        // If the bytes received is 0, then return NA
        return @"NA";
    }
    return @"NA"; // Return NA if Softrock not present
}

- (void)setWriteFrequency:(uint64_t)writeFrequency {
    if (devHandle) {
        uint32_t iFreq = 0;
        
        double dFreq;
        
        // Set frequency
        dFreq = writeFrequency;
        if (dFreq != 0) dFreq = dFreq / 1000000;
        iFreq = (dFreq * 4) * (1UL << 21);
        libusb_control_transfer(devHandle, CTRL_OUT, 0x32, 0, 0, (unsigned char *)&iFreq,
                                sizeof(iFreq), 500);
    }
}

- (uint64_t)readFrequency {
    if (devHandle) {
        
        uint32_t iFreq = 0;
        
        int r;
        
        double dFreq;
        
        // Get frequency
        r = libusb_control_transfer(devHandle, CTRL_IN, 0x3a, 0, 0, (unsigned char *)&iFreq,
                                    sizeof(iFreq), 500);
        if (r == 4) {
            if (iFreq != 0) dFreq = ((double)iFreq / (1UL << 21) / 4);
            dFreq = dFreq * 1000000;
            dFreq = dFreq + 1; // rounding error - round up 1 Hz
            return (uint64_t)dFreq;
        } else {
            return 0;
        }
    }
    return 0;
}

- (BOOL)openSoftrock {
    int rc;
    
    libusb_init(&myContext);
    
    rc = libusb_hotplug_register_callback(myContext, LIBUSB_HOTPLUG_EVENT_DEVICE_ARRIVED |
                                          LIBUSB_HOTPLUG_EVENT_DEVICE_LEFT, LIBUSB_HOTPLUG_ENUMERATE, DG8SAQ_VID, DG8SAQ_PID,
                                          LIBUSB_HOTPLUG_MATCH_ANY, hotplug_callback, NULL,
                                          &callbackHandle);
    
    if (LIBUSB_SUCCESS != rc) {
        NSLog(@"Error creating libusb hotplug callback.");
        libusb_exit(myContext);
        return false;
    } else {
        return true;
    }
}

- (void)closeSoftrock {
    NSLog(@"closeSoftrock called");
    if (myContext) {
        libusb_hotplug_deregister_callback(myContext, callbackHandle);
        libusb_exit(myContext);
    }
}

- (void)handleUSBEvent {
    if (devHandle) {
        [self setSoftrockPresent:true];
    } else {
        [self setSoftrockPresent:false];
    }
    
    libusb_handle_events_completed(myContext, NULL);
}

@end