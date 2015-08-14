//
//  MKDNetClient.m
//
//  Created by Morgan Davis on 3/25/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

#import "MKDNetClient.h"
#import "enet.h"
#import <stdlib.h>


@interface MKDNetClient ()

- (void)eventLoop;

@property(atomic, strong, readwrite)	NSString					*address;
@property(atomic, assign, readwrite)	uint16_t					port;
@property(atomic, assign, readwrite)	uint8_t						maxChannels;
@property(atomic, weak, readwrite)		id<MKDNetClientDelegate>    delegate;
@property(atomic, assign)				ENetHost					*host;
@property(atomic, assign)				ENetPeer					*peer;
@property(atomic, strong)				dispatch_queue_t			eventQueue;
@property(atomic, assign, readwrite)	BOOL						isConnected;
@property(atomic, assign, readwrite)    u_int32_t                   peerID;

@end


@implementation MKDNetClient

#pragma mark - Public

+ (MKDNetClient *)clientWithDestinationAddress:(NSString *)address port:(uint16_t)port maxChannels:(uint8_t)maxChannels delegate:(id<MKDNetClientDelegate>)delegate
{
	MKDNetClient *client = [[MKDNetClient alloc] init];
	client.address = address;
	client.port = port;
	client.delegate = delegate;
	
    if (enet_initialize () != 0) {
        NSLog(@"*** Error initializing ENet! ***");
        return nil;
    }
    
    client.host = enet_host_create(NULL,
                                   1,
                                   maxChannels,
                                   0,
                                   0);
    
    if (client.host == NULL) {
        NSLog(@"*** Error creating ENet client host! ***");
        return nil;
    }
    else {
        NSLog(@"Client created.");
    }
    
    
	return client;
}

- (void)connect
{
	self.eventQueue = dispatch_queue_create("com.morgankdavis.netclient.eventLoop", NULL);
	dispatch_async(self.eventQueue, ^{
		[self eventLoop];
	});
	
	ENetAddress address;
	enet_address_set_host(&address, [self.address cStringUsingEncoding:NSASCIIStringEncoding]);
	address.port = self.port;

	u_int32_t peerID = arc4random_uniform(SHRT_MAX);
    self.peerID = peerID;
	NSLog(@"peerID: %d", peerID);
	
	self.peer = enet_host_connect(self.host,
								  &address,
								  self.maxChannels,
								  (enet_uint32)peerID);
	
	if (self.peer == NULL) {
		NSLog(@"*** Connection failed. ***");
		[self.delegate client:nil didFailToConnect:nil];
	}
}

- (void)disconnect
{
	
}

- (void)sendPacket:(NSData *)packetData channel:(uint8_t)channel flags:(MKDNetPacketFlag)flags
{
	if (self.isConnected) {
		ENetPacket *packet = enet_packet_create([packetData bytes],
												[packetData length],
												flags);
		enet_peer_send(self.peer,
					   channel,
					   packet);
		
		enet_host_flush(self.host);
	}
	else {
		NSLog(@"Not connected!");
	}
}

#pragma mark - Private

- (void)eventLoop
{
    ENetEvent event;
	while (YES) {
		while (enet_host_service(self.host, &event, 1) > 0) {
			switch (event.type) {
					
				case ENET_EVENT_TYPE_CONNECT:
					self.isConnected = YES;
                    //[self.delegate client:self didConnectWithID:self.peerID];
                    [self performSelectorOnMainThread:@selector(sendDelegateConnect) withObject:nil waitUntilDone:YES];
					break;
					
				case ENET_EVENT_TYPE_RECEIVE: {
					NSData *packetData = [[NSData alloc] initWithBytes:event.packet->data length:event.packet->dataLength];
					//[self.delegate client:self didRecievePacket:packetData channel:event.channelID];
                    [self performSelectorOnMainThread:@selector(sendDelegateReceive:) withObject:@[packetData, @(event.channelID)] waitUntilDone:YES];
					break; }
					
				case ENET_EVENT_TYPE_DISCONNECT:
					self.isConnected = NO;
					return;
					
				default:
					break;
			}
		}
	}
}

- (void)sendDelegateConnect
{
    [self.delegate client:self didConnectWithID:self.peerID];
}

- (void)sendDelegateReceive:(NSArray *)args
{
    [self.delegate client:self didRecievePacket:args[0] channel:[args[1] unsignedIntValue]];
}

@end
