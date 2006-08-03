//
//  PacketHandler.h
//  Eavesdrop
//
//  Created by Eric Baur on Tue Oct 5 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

@protocol PacketHandler
- (oneway void)addPacket:(NSData *)packetData withHeader:(NSData *)headerData;
- (oneway void)addPacket:(NSDictionary *)packetDict;
- (void)retreivedAdditions;
- (BOOL)dataQueued;
- (BOOL)updateNeeded;
- (void)setUpdateNeeded:(BOOL)newState;
- (int)queueDepth;
- (oneway void)stopCapture;
@end
