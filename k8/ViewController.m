//
//  ViewController.m
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

#import "ViewController.h"
#import "VVCSoftrockUSBCtrl.h"

#define CTRL_IN                 (LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_ENDPOINT_IN)
#define CTRL_OUT                (LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_ENDPOINT_OUT)

#define DG8SAQ_VID 0x16c0
#define DG8SAQ_PID 0x05dc

static int VVCcontextforKVO;

@implementation ViewController {
    VVCSoftrockUSBCtrl *softrockUSB;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [softrockUSB closeSoftrock];
    NSLog(@"Viewcontroller notified of termination.");
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    softrockUSB = [[VVCSoftrockUSBCtrl alloc] init];
    
    [softrockUSB addObserver:self forKeyPath:@"softrockPresent" options:NSKeyValueObservingOptionNew context:&VVCcontextforKVO];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
    
    [self performSelectorInBackground:@selector(checkSoftrock:) withObject:nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != &VVCcontextforKVO) {
        // Pass on to the superclass if this is not for me
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    } else {
        // Else handle the change
        NSLog(@"KVO of Stockrock changed");
        if ([softrockUSB softrockPresent]) {
            [self performSelectorOnMainThread:@selector(softrockConnectedUpdate) withObject:nil waitUntilDone:true];
            
            //[self updateSoftrockDisplayValues];
            NSLog(@"From ViewController's KVO PoV rocky status changed to: present!");
        } else {
            [self performSelectorOnMainThread:@selector(softrockDisconnectedUpdate) withObject:nil waitUntilDone:true];
            NSLog(@"From ViewController's KVO PoV rocky status changed to: removed!");
        }
    }
}

- (void)softrockDisconnectedUpdate {
    [consoleWindow insertText:@"Softrock disconnected.\n"];
    [vfoA setStringValue:[NSString stringWithFormat:@"%llu", [softrockUSB readFrequency]]];
    [softrockConsole setStringValue:[softrockUSB firmwareRevision]];
}

- (void)softrockConnectedUpdate {
    [consoleWindow insertText:@"Softrock connected.\n"];
    [vfoA setStringValue:[NSString stringWithFormat:@"%llu", [softrockUSB readFrequency]]];
    [softrockConsole setStringValue:[softrockUSB firmwareRevision]];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)setvfoA:(NSTextField *)sender {
    if (softrockUSB) {
        [softrockUSB setWriteFrequency:(uint64_t)[vfoA integerValue]];
        [consoleWindow insertText:@"Sent frequency update request.\n"];
    }
}

- (IBAction)updatevfoA:(NSTextField *)sender {
}

- (void)checkSoftrock:(id)unused {
    @autoreleasepool {
        while (true) {
            [softrockUSB handleUSBEvent];
            usleep(10000);
        }
        
    }
}

@end
