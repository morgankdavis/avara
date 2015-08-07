//
//  MKDDirectMouseHelper.h
//
//  Created by Morgan Davis on 8/6/15.
//  Copyright © 2015 goosesensor. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, MKDDirectMouseAxis) {
    MKDDirectMouseAxisX = 0,
    MKDDirectMouseAxisY = 1
};

typedef NS_ENUM(NSInteger, MKDDirectMouseScrollDirection) {
    MKDDirectMouseScrollDirectionUp = 0,
    MKDDirectMouseScrollDirectionDown = 1
};


@protocol MKDDirectMouseHelperDelegate;


@interface MKDDirectMouseHelper : NSObject

- (instancetype)initWithDelegate:(id<MKDDirectMouseHelperDelegate>)delegate;
- (void)start;
- (void)stop;

@property(atomic, weak) id<MKDDirectMouseHelperDelegate> delegate;

@end


@protocol MKDDirectMouseHelperDelegate <NSObject>

- (void)helper:(MKDDirectMouseHelper *)helper didFindMouseID:(int)mouseID name:(NSString *)name driverName:(NSString *)driverName;
- (void)helper:(MKDDirectMouseHelper *)helper didGetRelativeMotion:(int)delta axis:(MKDDirectMouseAxis)axis mouseID:(int)mouseID;
- (void)helper:(MKDDirectMouseHelper *)helper didGetButtonPress:(int)buttonID mouseID:(int)mouseID;
- (void)helper:(MKDDirectMouseHelper *)helper didGetScroll:(int)wheelID direction:(MKDDirectMouseScrollDirection)direction mouseID:(int)mouseID;
- (void)helper:(MKDDirectMouseHelper *)helper didFailWithError:(int)error;

@end
