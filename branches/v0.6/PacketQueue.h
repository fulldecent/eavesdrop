//
//  PacketQueue.h
//  Eavesdrop
//
//  Created by Eric Baur on 5/28/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DOHelpers.h"
#import "CaptureHandlers.h"

#import "Packet.h"
#import "Dissector.h"
#import "Aggregate.h"

#define NO_DATA 0
#define HAS_DATA 1

@interface PacketQueue : NSObject <PacketQueue> {
	NSString *identifier;

	NSLock *queueLock;
	NSRecursiveLock *arrayLock;

	BOOL hasData;
	
	int packetArrayPosition;

	NSMutableArray *headerDataArray;
	NSMutableArray *packetDataArray;
	
	NSMutableArray *packetArray;
	
	NSMutableArray *newAggregateArray;
	NSMutableDictionary *aggregateDict;
	
	Class aggregateClass;
	NSMutableArray *aggregateClassArray;

	NSTimer *collectionTimer;
}

+ (PacketQueue *)collectorWithIdentifier:(NSString *)identifier;
+ (void)startCollectorWithIdentifier:(NSString *)identifier;
+ (void)stopCollectorWithIdentifier:(NSString *)identifier;

- (id)initWithIdentifier:(NSString *)ident;
- (NSString *)aggregateClassName;
- (void)setAggregateClassName:(NSString *)className;
- (void)setAggregateClass:(Class)newAggregate;

- (NSArray *)aggregateClassArray;
- (void)setAggregateClassArray:(NSArray *)newClassArray;

- (void)_resetAggregates;

- (void)collectPackets;
- (void)processPacketData:(NSData *)packetData withHeaderData:(NSData *)headerData;
- (void)processAggregateForPacket:(NSObject<Dissector> *)newPacket;

- (void)resetNewPacketIndex;
- (NSArray *)flushNewPacketArray;
- (NSArray *)flushNewAggregateArray;
- (NSDictionary *)aggregateDict;

@end
