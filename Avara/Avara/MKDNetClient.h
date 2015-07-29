//
//  MKDNetClient.h
//  MKDNetClientTest
//
//  Created by Morgan Davis on 3/25/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKDNetTypes.h"


@protocol MKDNetClientDelegate;


@interface MKDNetClient : NSObject

+ (MKDNetClient *)clientWithDestinationAddress:(NSString *)address port:(uint16_t)port maxChannels:(uint8_t)maxChannels delegate:(id<MKDNetClientDelegate>)delegate;
- (void)connect;
- (void)disconnect;
- (void)sendPacket:(NSData *)packetData channel:(uint8_t)channel flags:(MKDNetPacketFlag)flags;

@property(atomic, strong, readonly) NSString                    *address;
@property(atomic, readonly)			uint16_t                    port;
@property(atomic, readonly)			uint8_t                     maxChannels;
@property(atomic, weak, readonly)	id<MKDNetClientDelegate>    delegate;
@property(atomic, readonly)			BOOL                        isConnected;

@end


@protocol MKDNetClientDelegate <NSObject>

- (void)clientDidConnect:(MKDNetClient *)client;
- (void)client:(MKDNetClient *)client didFailToConnect:(NSError *)error;
- (void)clientDidDisconnect:(MKDNetClient *)client;
- (void)client:(MKDNetClient *)client didRecievePacket:(NSData *)packetData channel:(uint8_t)channel;

@end
