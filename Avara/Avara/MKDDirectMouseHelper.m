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

- (void)eventLoop;

@property(atomic, strong) NSString              *driverName;
@property(atomic, strong) NSMutableDictionary   *nameMap;
@property(atomic, assign) BOOL                  quit;
//@property(atomic, strong) dispatch_queue_t      eventQueue;
//@property(atomic, strong) NSTimer               *timer;

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

- (void)start
{
    self.quit = NO;
    
    const int available_mice = ManyMouse_Init();
    
    if (available_mice < 0) {
        NSLog(@"ManyMouse failed to initialize!\n");
        [self.delegate helper:self didFailWithError:available_mice];
    }
    else if (available_mice == 0) {
        NSLog(@"No mice detected!\n");
        [self.delegate helper:self didFailWithError:available_mice];
    }
    else {
        self.nameMap = [NSMutableDictionary dictionaryWithCapacity:available_mice];
        int i;
        NSString *driverName = [NSString stringWithCString:ManyMouse_DriverName() encoding:NSASCIIStringEncoding];
        NSLog(@"ManyMouse driver: %@\n", driverName);
        for (i = 0; i < available_mice; i++) {
            NSString *deviceName = [NSString stringWithCString:ManyMouse_DeviceName(i) encoding:NSASCIIStringEncoding];
            self.nameMap[@(i)] = deviceName;
            NSLog(@"#%d: %@\n", i, deviceName);
            [self.delegate helper:self didFindMouseID:i name:deviceName driverName:driverName];
        }
    }
    
//    self.eventQueue = dispatch_queue_create("com.morgankdavis.rawmouse.eventLoop", NULL);
//    dispatch_async(self.eventQueue, ^{
//        [self eventLoop];
//    });
    
    [self performSelectorInBackground:@selector(eventLoop) withObject:nil];
    
    //self.timer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(eventLoop) userInfo:nil repeats:YES];
}

- (void)stop
{
    self.quit = YES;
}

#pragma mark - Private

- (void)eventLoop
{
    while (!self.quit) {
        while (ManyMouse_PollEvent(&event)) {
            if (event.type == MANYMOUSE_EVENT_ABSMOTION) {
                NSLog(@"Mouse #%u absolute motion %s %d\n", event.device, event.item == 0 ? "X" : "Y", event.value);
            }
            else if (event.type == MANYMOUSE_EVENT_RELMOTION) {
                NSLog(@"Mouse #%u relative motion %s %d\n", event.device, event.item == 0 ? "X" : "Y", event.value);
                [self.delegate helper:self didGetRelativeMotion:event.value axis:event.item mouseID:event.device];
            }
            else if (event.type == MANYMOUSE_EVENT_BUTTON) {
                NSLog(@"Mouse #%u button %u %s\n", event.device, event.item, event.value ? "down" : "up");
            }
            else if (event.type == MANYMOUSE_EVENT_SCROLL) {
                const char *wheel;
                const char *direction;
                if (event.item == 0) {
                    wheel = "vertical";
                    direction = ((event.value > 0) ? "up" : "down");
                }
                else {
                    wheel = "horizontal";
                    direction = ((event.value > 0) ? "right" : "left");
                }
                NSLog(@"Mouse #%u wheel %s %s\n", event.device,
                      wheel, direction);
            }
            else if (event.type == MANYMOUSE_EVENT_DISCONNECT) {
                NSLog(@"Mouse #%u disconnect\n", event.device);
            }
            else {
                NSLog(@"Mouse #%u unhandled event type %d\n", event.device, event.type);
            }
        }
    }
    
    ManyMouse_Quit();
}

@end
