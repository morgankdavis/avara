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

typedef NS_ENUM(NSInteger, MKDDirectMouseVerticalScrollDirection) {
    MKDDirectMouseVerticalScrollDirectionUp = 0,
    MKDDirectMouseVerticalScrollDirectionDown = 1
};

typedef NS_ENUM(NSInteger, MKDDirectMouseHorizontalScrollDirection) {
    MKDDirectMouseHorizontalScrollDirectionRight = 0,
    MKDDirectMouseHorizontalScrollDirectionLeft = 1
};


@protocol MKDDirectMouseHelperDelegate;


@interface MKDDirectMouseHelper : NSObject

- (instancetype)initWithDelegate:(id<MKDDirectMouseHelperDelegate>)delegate;
//- (MKDDirectMouseHelper *)sharedHelper;
- (void)findMice;
- (void)pump;
- (void)quit;

@property(atomic, weak) id<MKDDirectMouseHelperDelegate> delegate;

@end


@protocol MKDDirectMouseHelperDelegate <NSObject>

- (void)directMouseHelper:(MKDDirectMouseHelper *)helper didFindMouseID:(int)mouseID name:(NSString *)name driverName:(NSString *)driverName;
- (void)directMouseHelper:(MKDDirectMouseHelper *)helper didGetRelativeMotion:(int)delta axis:(MKDDirectMouseAxis)axis mouseID:(int)mouseID;
- (void)directMouseHelper:(MKDDirectMouseHelper *)helper didGetButtonDown:(int)buttonID mouseID:(int)mouseID;
- (void)directMouseHelper:(MKDDirectMouseHelper *)helper didGetButtonUp:(int)buttonID mouseID:(int)mouseID;
- (void)directMouseHelper:(MKDDirectMouseHelper *)helper didGetVerticalScroll:(MKDDirectMouseVerticalScrollDirection)direction mouseID:(int)mouseID;
- (void)directMouseHelper:(MKDDirectMouseHelper *)helper didGetHorizontalScroll:(MKDDirectMouseHorizontalScrollDirection)direction mouseID:(int)mouseID;
- (void)directMouseHelper:(MKDDirectMouseHelper *)helper didFailWithError:(int)error;

@end
