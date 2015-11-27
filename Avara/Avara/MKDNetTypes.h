//
//  MKDNetTypes.h
//
//  Created by Morgan Davis on 3/25/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

#ifndef MKDNetTypes_h
#define MKDNetTypes_h

typedef NS_ENUM(NSUInteger, MKDNetPacketFlag) {
	MKDNetPacketFlagReliable =      (1 << 0),
	MKDNetPacketFlagUnsequenced =   (1 << 1)
};

#endif
