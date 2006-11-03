//
//  Dissector.m
//  Eavesdrop
//
//  Created by Eric Baur on 6/19/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "Dissector.h"


@implementation Dissector

static int dissectorCount;

+ (void)initialize
{
	ENTRY( @"initialize" );
	dissectorCount = 0;
}


+ (BOOL)canDecodePacket:(NSObject<Plugin> *)testPacket
{
	return YES;
}

+ (id)packetWithHeaderData:(NSData *)newHeader packetData:(NSData *)newPacket
{
	//not sure if this is actually how I want to start it out...
	Class<Dissector> tempClass = [[[super registeredDissectors] valueForKey:@"packet"] objectForKey:@"dissectorClassName"];	
	Dissector *nextPacket = [[[tempClass alloc] initWithHeaderData:newHeader packetData:newPacket] autorelease];
	Dissector *tempPacket;
	
	if (!nextPacket) {
		ERROR( @"failed to init packet" );
	}

	NSString *tempDissectorString;

	while (nextPacket) {
		//DEBUG1( @"nextPacket is now: ", [nextPacket description] );
		tempPacket = nextPacket;
		nextPacket = nil;
		
		//give the current dissector a chance to request a dissector (eg. IP->TCP)
		tempDissectorString = [tempPacket preferedDissectorProtocol];
		if (tempDissectorString) {
			//DEBUG1( @"preferedDissector set, using %@", tempDissectorString );
			tempClass = [[[super registeredDissectors] valueForKey:tempDissectorString] valueForKey:@"dissectorClassName"];
			nextPacket = [[tempClass alloc] initFromParent:tempPacket];
		} else {
		//look for an appropriate dissector based on what is registered
			NSDictionary *tempDict = [[super registeredDissectors] objectForKey:[tempPacket protocolString]];
			//INFO1( @"subDissectors -> %@", [tempDict description] );
			NSEnumerator *en = [[tempDict objectForKey:@"subDissectors"] objectEnumerator];

			while ( tempDissectorString=[en nextObject] ) {
				tempClass = [[[super registeredDissectors] objectForKey:tempDissectorString] objectForKey:@"dissectorClassName"];
				//DEBUG1( @"checking class: %@", tempDissectorString );
				if ( [tempClass canDecodePacket:tempPacket] ) {
					nextPacket = [[[tempClass alloc] initFromParent:tempPacket] autorelease];
					break;
				}
			}
		}
	}
	return tempPacket;
}

#pragma mark -
#pragma mark Setup methods

- (id)initWithHeaderData:(NSData *)header packetData:(NSData *)packet
{
	self = [super init];
	// this is almost exactly what Packet does... where does it make more sense?
	if (self) {
		dissectorNumber = ++dissectorCount;
		headerData = [header retain];
		payloadData = [packet retain];	//may want to hide this with an accessor
		//packetData = [packet retain];
		
		parent = nil;
		child = nil;
	}
	return self;
}

- (id)initFromParent:(id)parentPacket
{
	self = [super init];
	if (self) {
		dissectorNumber = ++dissectorCount;
		headerData = nil;
		payloadData = nil;
		//packetData = nil;
		child = nil;
		parent = [parentPacket retain];
		//[parentPacket setChild:self];
	}
	return self;
}

- (NSData *)headerData 
{
	if (headerData) {
		return headerData;
	} else if (parent) {
		return [parent headerData];
	} else {
		return [NSData data];
	}
}

- (const void *)headerBytes
{
	return [headerData bytes];
}

- (NSData *)payloadData
{
	if (payloadData) {
		return payloadData;
	} else if (parent) {
		return [parent payloadData];
	} else {
		return nil;
	}
}

- (const void *)payloadBytes
{
	return [payloadData bytes];
}

- (void)setChild:(NSObject<Dissector> *)childPacket
{
	[child release];
	child = [childPacket retain];
}

- (NSString *)preferedDissectorProtocol
{
	return nil;
}

#pragma mark -
#pragma mark Meta data

- (NSDictionary *)allKeyNames
{
	NSMutableDictionary *tempDict = [[[self class] keyNames] mutableCopy];
	if ( parent ) {
		[tempDict addEntriesFromDictionary:[parent allKeyNames] ];
	}
	return [tempDict copy];
}

- (NSArray *)protocolsArray
{
	NSMutableArray *tempArray = [NSMutableArray array];
	
	if (parent)
		[tempArray addObjectsFromArray:[parent protocolsArray] ];
		
	[tempArray addObject:[self protocolString] ];
	
	return [tempArray copy];
}

#pragma mark -
#pragma mark View methods

- (NSArray *)detailColumnsArray
{
	ENTRY( @"detailColumnsArray" );
	
	NSMutableArray *tempArray = [NSMutableArray array];
	if (parent)
		[tempArray addObjectsFromArray:[parent detailColumnsArray] ];

	DEBUG1( @"looking up columns dict: %@", [self protocolString] );
	NSArray *columnDicts = [[[self registeredDissectors] valueForKey:[self protocolString]] valueForKey:@"detailColumns"];
	DEBUG1( @"got %d columns", [columnDicts count] );
	
	NSEnumerator *en = [columnDicts objectEnumerator];
	NSDictionary *tempDict;

	NSTableColumn *tempColumn;
	NSTableHeaderCell *tempHeaderCell;
	while ( tempDict=[en nextObject] ) {
		tempColumn = [[NSTableColumn alloc] initWithIdentifier:[tempDict valueForKey:@"columnKey"] ];
		tempHeaderCell = [[NSTableHeaderCell alloc] init];
		
		[tempHeaderCell setStringValue:[tempDict valueForKey:@"name"] ];
		
		[tempColumn setWidth:[[tempDict valueForKey:@"width"] floatValue] ];
		[tempColumn setHeaderCell:tempHeaderCell];
		
		[[tempColumn dataCell] setFont:[NSFont fontWithName:@"Lucida Grande" size:9.0] ];
		
		[tempArray addObject:tempColumn];
	}
	
	DEBUG1( @"there are now %d table columns", [tempArray count] );
	return tempArray;
}


#pragma mark -
#pragma mark Overriden methods

- (id)valueForUndefinedKey:(NSString *)key
{	
	if (parent) {
		return [parent valueForKey:key];
	} else {
		return nil;
	}
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"Class => %@\tdetails => %@",
		[self className],
		[self detailsDictionary]
	];
}

@end
