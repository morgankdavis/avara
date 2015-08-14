//
//  MKDNetServer.m
//
//  Created by Morgan Davis on 3/25/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

#import "MKDNetServer.h"
#import "enet.h"


@interface MKDNetServer ()

- (void)eventLoop;

@property(atomic, assign, readwrite)	uint16_t					port;
@property(atomic, assign, readwrite)	size_t						maxClients;
@property(atomic, assign, readwrite)	uint8_t						maxChannels;
@property(atomic, weak, readwrite)		id<MKDNetServerDelegate>	delegate;
@property(atomic, assign)				ENetHost					*host;
@property(atomic, strong)				dispatch_queue_t			eventQueue;

@end


@implementation MKDNetServer

#pragma mark - Public

+ (MKDNetServer *)serverWithPort:(uint16_t)port maxClients:(size_t)maxClients maxChannels:(uint8_t)maxChannels delegate:(id<MKDNetServerDelegate>)delegate
{
	MKDNetServer *server = [[MKDNetServer alloc] init];
	server.port = port;
	server.maxClients = maxClients;
	server.maxChannels = maxChannels;
	server.delegate = delegate;
	
	if (enet_initialize () != 0) {
		NSLog(@"*** Error initializing ENet! ***");
		return nil;
	}
	
	ENetAddress address;
	address.host = ENET_HOST_ANY;
	address.port = port;
	server.host = enet_host_create (&address,
									maxClients,
									maxChannels,
									0,
									0);
	if (server.host == NULL) {
		NSLog(@"*** Error creating ENet server host! ***");
		return nil;
	}
	else {
		NSLog(@"Server created.");
	}
	
	server.eventQueue = dispatch_queue_create("com.morgankdavis.netserver.eventLoop", NULL);
	dispatch_async(server.eventQueue, ^{
		[server eventLoop];
	});
	
	return server;
}

- (void)broadcastPacket:(NSData *)packetData channel:(uint8_t)channel flags:(MKDNetPacketFlag)flags
{
	ENetPacket *packet = enet_packet_create([packetData bytes],
											[packetData length],
											flags);
	enet_host_broadcast(self.host,
						channel,
						packet);
	
    //enet_packet_destroy(packet); // do we need to call this at some point? it causes random crashes here.
}

#pragma mark - Private

- (void)eventLoop
{
	ENetEvent event;
	while (YES) {
		while (enet_host_service(self.host, &event, 1) > 0) {
			switch (event.type) {
					
				case ENET_EVENT_TYPE_CONNECT: {
					u_int32_t peerID = event.data;
					//[self.delegate server:self didConnectClient:peerID];
                    [self performSelectorOnMainThread:@selector(sendDelegateConnect:) withObject:@(peerID) waitUntilDone:YES];
					break; }
					
				case ENET_EVENT_TYPE_RECEIVE: {
                    u_int32_t peerID = event.data;
                    //NSLog(@"ENET_EVENT_TYPE_RECEIVE: peerID: %d", peerID);
                    
					NSData *packetData = [[NSData alloc] initWithBytes:event.packet->data length:event.packet->dataLength];
					//[self.delegate server:self didRecievePacket:packetData fromClient:peerID channel:event.channelID];
                    [self performSelectorOnMainThread:@selector(sendDelegateReceive:) withObject:@[packetData, @(peerID), @(event.channelID)] waitUntilDone:YES];
					break; }
					
				case ENET_EVENT_TYPE_DISCONNECT:
					//					sprintf(buffer, "%s has disconnected.", (char*)event.peer->data);
					//					packet = enet_packet_create(buffer, strlen(buffer)+1, 0);
					//					enet_host_broadcast(server, 1, packet);
					//					free(event.peer->data);
					//					event.peer->data = NULL;
					break;
					
				default:
					break;
			}
		}
	}
}

- (void)sendDelegateConnect:(NSNumber *)peerID
{
    [self.delegate server:self didConnectClient:[peerID unsignedIntValue]];
}

- (void)sendDelegateReceive:(NSArray *)args
{
    [self.delegate server:self didRecievePacket:args[0] fromClient:[args[1] unsignedIntValue] channel:[args[2] unsignedIntValue]];
}

@end
