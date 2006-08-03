//
//  CaptureQueue.h
//  Eavesdrop
//
//  Created by Eric Baur on Sun Aug 01 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "sniff.h"
#import <sys/time.h>

#import <pcap.h>
#import <pcap-namedb.h>

#import "Conversation.h"
#import "PacketHandler.h"

#define NO_DATA 0
#define HAS_DATA 1

@interface CaptureQueue : NSObject <PacketHandler>
{
	NSMutableArray *packetQueue;
	NSMutableArray *headerQueue;
	
	NSMutableDictionary *conversations;
	NSMutableArray *additions;
	
	BOOL updateNeeded;
	BOOL dataQueued;

	NSConditionLock *queueLock;
	NSLock *additionsLock;
}

+ (void)queueThreadWithSettings:(NSDictionary *)settings;
+ (id)queueWithController:(id)aController;
- (id)initWithController:(id)aController;

- (void)readPackets;
- (NSDictionary *)dictionaryFromPacket:(NSData *)packetData withHeader:(NSData *)headerData;
- (void)addPacketDictionary:(NSDictionary *)packetDict;

- (void)stopCapture;
@end
