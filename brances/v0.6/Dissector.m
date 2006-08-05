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
		tempPacket = nextPacket;
		nextPacket = nil;
		
		//give the current dissector a chance to request a dissector (eg. IP->TCP)
		tempDissectorString = [tempPacket preferedDissectorProtocol];
		if (tempDissectorString) {
			tempClass = [[[super registeredDissectors] valueForKey:tempDissectorString] valueForKey:@"dissectorClassName"];
			nextPacket = [[tempClass alloc] initFromParent:tempPacket];
		} else {
		//look for an appropriate dissector based on what is registered
			NSDictionary *tempDict = [[super registeredDissectors] objectForKey:[tempPacket protocolString]];
			NSEnumerator *en = [[tempDict objectForKey:@"subDissectors"] objectEnumerator];

			while ( tempDissectorString=[en nextObject] ) {
				tempClass = [[[super registeredDissectors] objectForKey:tempDissectorString] objectForKey:@"dissectorClassName"];
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
	if (self) {
		dissectorNumber = ++dissectorCount;
		headerData = [header retain];
		payloadData = [packet retain];	//may want to hide this with an accessor
		packetData = [packet retain];
		
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
		packetData = nil;
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

- (NSData *)packetData 
{
	if (packetData)
		return packetData;
	else if (parent)
		return [parent packetData];
	else
		return nil;
}

- (const void *)packetBytes
{
	return [[self packetData] bytes];
}

- (NSData *)payloadData
{
	if (packetData) {
		return payloadData;
	} else if (parent) {
		return [parent payloadData];
	} else {
		return packetData;	//pretend payload is the entire packet
	}
}

- (const void *)payloadBytes
{
	return [packetData bytes];
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
#pragma mark Protocol Instance methods

- (NSNumber *)number
{
	NSNumber *tempValue = [self valueForUndefinedKey:@"number"];
	if (tempValue)
		return tempValue;
	else
		return [NSNumber numberWithInt:dissectorNumber];
}

- (NSString *)sourceString
{
	NSString *tempValue = [self valueForUndefinedKey:@"sourceString"];
	if (tempValue)
		return tempValue;
	else
		return @"sourceString";
}

- (NSString *)destinationString
{
	NSString *tempValue = [self valueForUndefinedKey:@"destinationString"];
	if (tempValue)
		return tempValue;
	else
		return @"destinationString";
}

- (NSString *)typeString
{
	NSString *tempValue = [self valueForUndefinedKey:@"destinationString"];
	if (tempValue)
		return tempValue;
	else
		return @"typeString";
}

- (NSString *)infoString
{
	NSString *tempValue = [self valueForUndefinedKey:@"infoString"];
	if (tempValue)
		return tempValue;
	else
		return @"infoString";
}

- (NSString *)flagsString
{
	NSString *tempValue = [self valueForUndefinedKey:@"flagsString"];
	if (tempValue)
		return tempValue;
	else
		return @"flagsString";
}

- (NSString *)descriptionString
{
	NSString *tempValue = [self valueForUndefinedKey:@"descriptionString"];
	if (tempValue)
		return tempValue;
	else
		return @"descriptionString";
}

- (NSString *)protocolString
{
	return @"";
}

+ (NSDictionary *)keyNames
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		@"#",			@"number",
		@"Source",		@"sourceString",
		@"Destination",	@"destinationString",
		@"Type",		@"typeString",
		@"Flags",		@"flagsString",
		@"Info",		@"infoString",
		@"Description",	@"descriptionString",
		nil
	];
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
