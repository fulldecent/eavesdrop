//
//  PacketQueue.m
//  Eavesdrop
//
//  Created by Eric Baur on 5/28/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "PacketQueue.h"


@implementation PacketQueue

#pragma mark -
#pragma mark Setup methods

static NSMutableDictionary *collectors;

+ (void)initialize
{
	ENTRY( @"initialize" );
	collectors = [[NSMutableDictionary alloc] init];
}

+ (PacketQueue *)collectorWithIdentifier:(NSString *)identifier
{
	return [collectors objectForKey:identifier];
}

+ (void)startCollectorWithIdentifier:(NSString *)identifier
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	ENTRY1( @"startCollectorWithIdentifier:%@", identifier );
	if ( [collectors objectForKey:identifier] ) {
		ERROR( @"collector identifier already exists, returning" );
		return;
	}
	PacketQueue *newCollector = [[[PacketQueue alloc] initWithIdentifier:identifier] autorelease];
	[collectors setObject:newCollector forKey:identifier];

	[[NSRunLoop currentRunLoop] run];
	EXIT1( @"startCollectorWithIdentifier:%@", identifier );
	[pool release];
	[NSThread exit];
}

+ (void)stopCollectorWithIdentifier:(NSString *)identifier
{
	ENTRY1( @"stopCollectorWithIdentifier:%@", identifier );
	[[collectors objectForKey:identifier] stopCollecting];
}

- (id)initWithIdentifier:(NSString *)ident
{
	ENTRY1( @"initWithIdentifier:%@", ident );
	self = [super init];
	if (self) {
		[DOHelpers vendObject:self withName:ident local:YES];
		identifier = [ident retain];
		queueLock = [[NSLock alloc] init];
		arrayLock = [[NSRecursiveLock alloc] init];

		hasData = NO;
		packetArrayPosition = 0;

		packetDataArray = [[NSMutableArray alloc] init];
		headerDataArray = [[NSMutableArray alloc] init];

		packetArray = [[NSMutableArray alloc] init];
		
		newAggregateArray = [[NSMutableArray alloc] init];
		aggregateDict = [[NSMutableDictionary alloc] init];

		collectionTimer = [[NSTimer
			scheduledTimerWithTimeInterval:0.01
			target:self
			selector:@selector(collectPackets)
			userInfo:nil
			repeats:YES
		] retain];
	}
	return self;
}

#pragma mark -
#pragma mark Accessor methods

- (NSString *)aggregateClassName
{
	NSString *tempValue = [aggregateClass performSelector:@selector(className)];
	DEBUG1( @"aggregateClassName: %@", tempValue );
	if (aggregateClass)
		return tempValue;
	else
		return [Aggregate className];
}

- (void)setAggregateClassName:(NSString *)className
{
	[self setAggregateClass:NSClassFromString(className)];
}

- (void)setAggregateClass:(Class)newAggregate
{
	ENTRY1( @"setAggregateClass: %@", [newAggregate performSelector:@selector(className)]  );
	if ( newAggregate!=[Aggregate class] && [newAggregate conformsToProtocol:@protocol(Aggregate)] )
		aggregateClass = newAggregate;
	else
		aggregateClass = nil;
	
	[self _resetAggregates];
	//EXIT( @"setAggregateClass" );
}

- (NSArray *)aggregateClassArray
{
	if ( aggregateClass ) {
		return [[NSArray arrayWithObject:NSStringFromClass(aggregateClass)]
			arrayByAddingObjectsFromArray:aggregateClassArray
		];
	} else {
		return nil;
	}
}

- (void)setAggregateClassArray:(NSArray *)newClassArray
{
	ENTRY( @"setAggregateClassArray" );
	INFO( [newClassArray description] );
	//need to add other processing
	[aggregateClassArray release];
	if ( newClassArray && [newClassArray count]!=0 ) {
		NSString *tempString = [[newClassArray objectAtIndex:0] valueForKey:@"aggregateClassName"] ;
		aggregateClass = NSClassFromString( tempString );

		aggregateClassArray = [[[newClassArray
			subarrayWithRange:NSMakeRange(1,[newClassArray count]-1)]
				valueForKeyPath:@"@unionOfObjects.aggregateClassName"
		] retain];
		
		DEBUG1( @"aggregateClass now set to: %@", [aggregateClass className] );
	} else {
		DEBUG( @"clearing out aggregate (blank or nil array passed)" );
		aggregateClass = nil;
		aggregateClassArray = nil;
	}
	[self _resetAggregates];
}

- (void)_resetAggregates
{
	DEBUG( @"removing data from old aggregate dictionary" );
	[aggregateDict removeAllObjects];
	[newAggregateArray removeAllObjects];
	NSEnumerator *en = [packetArray objectEnumerator];
	NSObject<Dissector> *tempPacket;
	DEBUG( @"re-processing packets for dictionary" );
	[arrayLock lock];
	while ( tempPacket=[en nextObject] ) {
		[self processAggregateForPacket:tempPacket];
	}
	[arrayLock unlock];
}

- (void)collectPackets
{
	if (!(hasData && [headerDataArray count] && [packetDataArray count]) ) return;
	
	BOOL stillCollecting = YES;
	while (stillCollecting) {
		[queueLock lock];
		[self
			processPacketData:[packetDataArray objectAtIndex:0]
			withHeaderData:[headerDataArray objectAtIndex:0]
		];
		[packetDataArray removeObjectAtIndex:0];
		[headerDataArray removeObjectAtIndex:0];
		
		if ( [packetDataArray count] ) {
			[queueLock unlock];
		} else {
			hasData = NO;
			stillCollecting = NO;
			[queueLock unlock];
		}
	}
}

- (void)processPacketData:(NSData *)packetData withHeaderData:(NSData *)headerData
{
	NSObject<Dissector> *newPacket;

	newPacket = [Dissector packetWithHeaderData:headerData packetData:packetData];
	[self processAggregateForPacket:newPacket];

	[arrayLock lock];
	[packetArray addObject:newPacket];
	[arrayLock unlock];
}

- (void)processAggregateForPacket:(NSObject<Dissector> *)newPacket
{
	if ([aggregateClass conformsToProtocol:@protocol(Aggregate)]) {
		NSString *aggregateIdentifier = [aggregateClass aggregateIdentifierForPacket:newPacket];
		NSObject<Aggregate> *aggregate = [aggregateDict objectForKey:aggregateIdentifier];
		if (aggregate) {
			[aggregate addPacket:newPacket];
		} else {
			//DEBUG1( @"new ID: %@", aggregateIdentifier );
			aggregate = [[aggregateClass alloc] initWithPacket:newPacket usingSubAggregates:aggregateClassArray];
			[arrayLock lock];
			[aggregateDict setObject:aggregate forKey:aggregateIdentifier];
			[newAggregateArray addObject:aggregate];
			[arrayLock unlock];
		}
	}
}

- (void)resetNewPacketIndex
{
	ENTRY( @"resetNewPacketIndex" );
	[arrayLock lock];
	packetArrayPosition = 0;
	[arrayLock unlock];
}

- (NSArray *)flushNewPacketArray
{
	[arrayLock lock];

	int count = [packetArray count] - packetArrayPosition;
	if (count==0) {
		[arrayLock unlock];
		return nil;
	} else {
		DEBUG1( @"flushing %d packets", count );
	}
	NSArray *tempArray = [packetArray objectsAtIndexes:
		[NSIndexSet indexSetWithIndexesInRange:
			NSMakeRange(packetArrayPosition, count)
		]
	];
	packetArrayPosition += count;	//reset position index
	
	[arrayLock unlock];
	
	return tempArray;
}

- (NSArray *)flushNewAggregateArray
{
	[arrayLock lock];
	
	int count = [newAggregateArray count];
	if ( count==0 ) {
		[arrayLock unlock];
		return nil;
	}
	NSArray *tempArray = [newAggregateArray copy];
	[newAggregateArray removeAllObjects];
	
	[arrayLock unlock];
	return tempArray;
}

- (NSDictionary *)aggregateDict
{
	return [aggregateDict copy];
}

#pragma mark -
#pragma mark PacketCollector methods

- (oneway void)addPacket:(NSData *)packetData withHeader:(NSData *)headerData
{
	//NSData *newPacket = [packetData copy];
	//NSData *newHeader = [headerData copy];
	[queueLock lock];
	[packetDataArray addObject:[packetData copy]];
	[headerDataArray addObject:[headerData copy]];
	[queueLock unlock];
	hasData = YES;
}

- (oneway void)stopCollecting
{
	ENTRY( @"stopCollecting]" );
	[collectionTimer invalidate];
	[self collectPackets];
}


@end
