//
//  Aggregate.h
//  Eavesdrop
//
//  Created by Eric Baur on 6/13/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*************/
/* There are three types of methods described in this protocol:		
/*
/*	FREEBIE																
/*		Implementations are supplied by the base Packet class, these
/*	methods are not recommended to be overridden.
/*
/*	RECOMMENDED
/*		Although there is a default implementation supplied, it is
/*	probably meaninless for your protocol.  Please override this to
/*	give specific information.
/* 
/*	REQUIRED
/*		These methods *must* be implemented for your subclass to
/*	function properly.
/*
/*************/

#import "Plugin.h"
#import "Dissector.h"
#import "PluginDefaults.h"
#import "BHDebug.h"

@protocol Aggregate <Plugin>

+ (NSString *)aggregateIdentifierForPacket:(NSObject<Dissector> *)newPacket;	/* REQUIRED */

- (id)initWithPacket:(NSObject<Dissector> *)firstPacket;						/* FREEBIE	*/
- (id)initWithPacket:(NSObject<Dissector> *)firstPacket
	usingSubAggregates:(NSArray *)subAggregates;								/* FREEBIE	*/
//Aggregates are immutable with respect to their sub-aggregates
//only packets can be added
- (BOOL)addPacket:(NSObject<Dissector> *)newPacket;								/* FREEBIE	*/
- (NSArray *)packetArray;														/* FREEBIE	*/
- (NSArray *)allPackets;														/* FREEBIE	*/
@end


@interface Aggregate : Plugin <Aggregate> {
	int number;
	NSString *identifier;
	NSMutableArray *packetArray;
	
	int captureLength;
	int length;
	
	NSObject<Dissector> *lastPacket;
	
	Class subAggregateClass;
	NSArray *subSubAggregateArray;
	NSMutableDictionary *subAggregateDict;
}

- (void)_processSubAggregateForPacket:(NSObject<Dissector> *)newPacket;

- (NSNumber *)packetCount;
- (NSNumber *)captureLength;
- (NSNumber *)length;
- (NSDate *)timestamp;
- (NSString *)timeString;

@end
