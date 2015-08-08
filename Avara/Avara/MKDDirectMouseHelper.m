//
//  MKDDirectMouseHelper.m
//
//  Created by Morgan Davis on 8/6/15.
//  Copyright © 2015 goosesensor. All rights reserved.
//

#import "MKDDirectMouseHelper.h"
#import "manymouse.h"


@interface MKDDirectMouseHelper() {
    ManyMouseEvent event;
}

@property(atomic, strong) NSString              *driverName;
//@property(atomic, strong) NSMutableDictionary   *nameMap;

@end


@implementation MKDDirectMouseHelper

#pragma mark - Public

- (instancetype)initWithDelegate:(id<MKDDirectMouseHelperDelegate>)delegate
{
    if (self = [super init]) {
        self.delegate = delegate;
        return self;
    }
    return nil;
}

//- (MKDDirectMouseHelper *)sharedHelper
//{
//    static MKDDirectMouseHelper *helper = nil;
//    if (!helper) helper = [[MKDDirectMouseHelper alloc] init];
//    return helper;
//}

- (void)findMice
{
    const int available_mice = ManyMouse_Init();
    
    if (available_mice < 0) {
        NSLog(@"ManyMouse failed to initialize!\n");
        [self.delegate directMouseHelper:self didFailWithError:available_mice];
    }
    else if (available_mice == 0) {
        NSLog(@"No mice detected!\n");
        [self.delegate directMouseHelper:self didFailWithError:available_mice];
    }
    else {
        //self.nameMap = [NSMutableDictionary dictionaryWithCapacity:available_mice];
        int i;
        NSString *driverName = [NSString stringWithCString:ManyMouse_DriverName() encoding:NSASCIIStringEncoding];
        NSLog(@"ManyMouse driver: %@\n", driverName);
        for (i = 0; i < available_mice; i++) {
            NSString *deviceName = [NSString stringWithCString:ManyMouse_DeviceName(i) encoding:NSASCIIStringEncoding];
            //self.nameMap[@(i)] = deviceName;
            NSLog(@"#%d: %@\n", i, deviceName);
            [self.delegate directMouseHelper:self didFindMouseID:i name:deviceName driverName:driverName];
        }
    }
}

- (void)pump
{
    while (ManyMouse_PollEvent(&event)) {
        if (event.type == MANYMOUSE_EVENT_ABSMOTION) {
            //NSLog(@"Mouse #%u absolute motion %s %d\n", event.device, event.item == 0 ? "X" : "Y", event.value);
        }
        else if (event.type == MANYMOUSE_EVENT_RELMOTION) {
            //NSLog(@"Mouse #%u relative motion %s %d\n", event.device, event.item == 0 ? "X" : "Y", event.value);
            [self.delegate directMouseHelper:self didGetRelativeMotion:event.value axis:event.item mouseID:event.device];
        }
        else if (event.type == MANYMOUSE_EVENT_BUTTON) {
            //NSLog(@"Mouse #%u button %u %s\n", event.device, event.item, event.value ? "down" : "up");
            if (event.value) { // down
                [self.delegate directMouseHelper:self didGetButtonDown:event.item mouseID:event.device];
            }
            else { // up
                [self.delegate directMouseHelper:self didGetButtonUp:event.item mouseID:event.device];
            }
        }
        else if (event.type == MANYMOUSE_EVENT_SCROLL) {
//            const char *wheel;
//            const char *direction;
            if (event.item == 0) {
//                wheel = "vertical";
//                direction = ((event.value > 0) ? "up" : "down");
                [self.delegate directMouseHelper:self
                            didGetVerticalScroll:((event.value > 0) ? MKDDirectMouseVerticalScrollDirectionUp : MKDDirectMouseVerticalScrollDirectionDown)
                                         mouseID:event.device];
            }
            else {
//                wheel = "horizontal";
//                direction = ((event.value > 0) ? "right" : "left");
                [self.delegate directMouseHelper:self
                            didGetHorizontalScroll:((event.value > 0) ? MKDDirectMouseHorizontalScrollDirectionRight : MKDDirectMouseHorizontalScrollDirectionLeft)
                                         mouseID:event.device];
            }
            //NSLog(@"Mouse #%u wheel %s %s\n", event.device, wheel, direction);
        }
        else if (event.type == MANYMOUSE_EVENT_DISCONNECT) {
            //NSLog(@"Mouse #%u disconnect\n", event.device);
        }
        else {
            //NSLog(@"Mouse #%u unhandled event type %d\n", event.device, event.type);
        }
    }
}

@end
