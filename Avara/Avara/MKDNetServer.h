//
//  MKDNetServer.h
//  MKDNetServerTest
//
//  Created by Morgan Davis on 3/25/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKDNetTypes.h"


@protocol MKDNetServerDelegate;


@interface MKDNetServer : NSObject

+ (MKDNetServer *)serverWithPort:(uint16_t)port maxClients:(size_t)maxClients maxChannels:(uint8_t)maxChannels delegate:(id<MKDNetServerDelegate>)delegate;
- (void)broadcastPacket:(NSData *)packetData channel:(uint8_t)channel flags:(MKDNetPacketFlag)flags;

@property(atomic, readonly)			uint16_t				port;
@property(atomic, readonly)			size_t					maxClients;
@property(atomic, readonly)			uint8_t					maxChannels;
@property(atomic, weak, readonly)	id<MKDNetServerDelegate> delegate;

@end


@protocol MKDNetServerDelegate <NSObject>

- (void)server:(MKDNetServer *)server didConnectClient:(uint32_t)client;
- (void)server:(MKDNetServer *)server didDisconnectClient:(uint32_t)client;
- (void)server:(MKDNetServer *)server didRecievePacket:(NSData *)packetData fromClient:(uint32_t)client channel:(uint8_t)channel;

@end