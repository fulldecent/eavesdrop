//
//  Aggregate.m
//  Eavesdrop
//
//  Created by Eric Baur on 6/13/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "Aggregate.h"


@implementation Aggregate

static int aggregateNumber;

//static NSView *payloadView;

#pragma mark -
#pragma mark Protocol Class methods

+ (void)initialize
{
	ENTRY( @"initialize" );
	if ( [self class]==[Aggregate class] ) {
		aggregateNumber = 0;

		[Dissector registerAggregateAndGetDefaultsWithSettings:[NSDictionary dictionaryWithObjectsAndKeys:
			@"Aggregate",	@"aggregateClassName",
			@"packet",		@"dissectorClassName",
			@"protocol",	@"packet",
			nil]
		];
	}
}

+ (NSString *)aggregateIdentifierForPacket:(NSObject<Dissector> *)newPacket
{
	return [[newPacket number] stringValue];
}

#pragma mark -
#pragma mark Setup methods

- (id)initWithPacket:(NSObject<Dissector> *)firstPacket
{
	return [self initWithPacket:firstPacket usingSubAggregates:nil];
}

- (id)initWithPacket:(NSObject<Dissector> *)firstPacket usingSubAggregates:(NSArray *)subAggregates
{
	//ENTRY( @"initWithPacket:usingSubAggregates:" );
	//INFO( [subAggregates description] ); 
	self = [super init];
	if (self) {
		number = ++aggregateNumber;
		packetArray = [[NSMutableArray alloc] init];
		identifier = [[[self class] aggregateIdentifierForPacket:firstPacket] retain];
		
		if (subAggregates && [subAggregates count]) {
			subAggregateClass = NSClassFromString( [subAggregates objectAtIndex:0] );
		}
		
		if ([subAggregateClass conformsToProtocol:@protocol(Aggregate)]) {
			//DEBUG1( @"set subAggregate to: %@", [subAggregateClass className] );
			subSubAggregateArray = [[subAggregates subarrayWithRange:NSMakeRange( 1, [subAggregates count]-1 )] retain];
			subAggregateDict  = [[NSMutableDictionary alloc] init];
		 } else {
			if (subAggregateClass)
				ERROR1( @"%@ does not conform to Aggregate protocol", [subAggregateClass className] );
			subAggregateClass = nil;
			subSubAggregateArray = nil;
			subAggregateDict = nil;
		}
		
		[self addPacket:firstPacket];
	}
	return self;
}

#pragma mark -
#pragma mark Adding packets & Accessors

- (BOOL)addPacket:(NSObject<Dissector> *)newPacket
{
	//DEBUG( @"addPacket:" );
	if ( [[[self class] aggregateIdentifierForPacket:newPacket] isEqualToString:identifier] ) {
		[lastPacket release];
		lastPacket = [newPacket retain];
		if ( subAggregateClass ) {
			[self _processSubAggregateForPacket:newPacket];
		} else {
			[packetArray addObject:newPacket];
		}
		return YES;
	} else {
		return NO;
	}
}

- (NSArray *)packetArray
{
	return [packetArray copy];
}

- (void)_processSubAggregateForPacket:(NSObject<Dissector> *)newPacket
{
	//ENTRY( @"_processSubAggregateForPacket:" );
	if ([subAggregateClass conformsToProtocol:@protocol(Aggregate)]) {
		NSString *aggregateIdentifier = [subAggregateClass aggregateIdentifierForPacket:newPacket];
		NSObject<Aggregate> *aggregate = [subAggregateDict objectForKey:aggregateIdentifier];
		if (aggregate) {
			[aggregate addPacket:newPacket];
		} else {
			//DEBUG1( @"new ID: %@", aggregateIdentifier );
			aggregate = [[subAggregateClass alloc] initWithPacket:newPacket usingSubAggregates:subSubAggregateArray];

			[subAggregateDict setObject:aggregate forKey:aggregateIdentifier];
			[packetArray addObject:aggregate];
		}
	}
}

#pragma mark -
#pragma mark Aggregate methods

- (NSNumber *)number
{
	return [NSNumber numberWithInt:number];
}

- (NSNumber *)packetCount
{
	return [NSNumber numberWithInt:[packetArray count]];
}

- (NSNumber *)captureLength
{
	return [packetArray valueForKeyPath:@"@sum.captureLength"];
}

- (NSNumber *)length 
{
	return [packetArray valueForKeyPath:@"@sum.length"];
}

- (NSDate *)timestamp 
{
	return nil;
}

- (NSString *)timeString
{
	return [NSString stringWithFormat:@"%f sec.", [(NSDate *)[lastPacket valueForKey:@"timestamp"]
			timeIntervalSinceDate:[[packetArray objectAtIndex:0] valueForKey:@"timestamp"]
		]
	];
}

#pragma mark -
#pragma mark Protocol Instance methods

- (id)sourceString
{
	return nil;
}

- (id)destinationString
{
	return nil;
}

- (id)typeString
{
	return nil;
}

- (id)infoString
{
	return nil;
}

- (id)flagsString
{
	return nil;
}

- (id)descriptionString
{
	return nil;
}

#pragma mark -
#pragma mark View methods

- (NSArray *)payloadViewArray
{
	return [[[self registeredAggregators] valueForKey:[self className]] valueForKey:@"payloadViews"];
}

- (NSArray *)detailColumnsArray
{
	ENTRY( @"detailColumnsArray" );
	NSString *primaryProtocol = [[[self registeredAggregators] valueForKey:[self className]] valueForKey:@"primaryProtocol"];

	if (!primaryProtocol)
		primaryProtocol = @"packet";

	NSArray *tempArray = [lastPacket valueForKey:@"detailColumnsArray"];
	return tempArray;
}

#pragma mark -
#pragma mark Meta data

- (NSDictionary *)allKeyNames
{
	NSMutableDictionary *tempDict = [[[self class] keyNames] mutableCopy];
	[tempDict addEntriesFromDictionary:[Plugin keyNames] ];
	return [tempDict copy];
}

- (id)valueForUndefinedKey:(NSString *)key
{
	return nil;
}

- (NSArray *)allPackets
{
	NSMutableArray *allPackets = [NSMutableArray array];
	
	NSEnumerator *en = [packetArray objectEnumerator];
	id tempItem;
	while ( tempItem=[en nextObject] ) {
		if ( [tempItem isKindOfClass:[Aggregate class]] ) {
			[allPackets addObjectsFromArray:[tempItem valueForKey:@"allPackets"] ];
		} else {
			[allPackets addObject:tempItem];
		}
	}
	return [allPackets copy];
}

@end
