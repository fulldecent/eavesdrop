//
//  TCPAggregate.m
//  Eavesdrop
//
//  Created by Eric Baur on 6/18/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "TCPAggregate.h"


@implementation TCPAggregate

+ (void)initialize
{
	ENTRY;
}

+ (NSString *)aggregateIdentifierForPacket:(NSObject<Dissector> *)newPacket
{
	if ( [newPacket respondsToSelector:@selector(tcpSourcePort)] ) {
		int sport = [[newPacket valueForKey:@"tcpSourcePort"] intValue];
		int dport = [[newPacket valueForKey:@"tcpDestinationPort"] intValue];
		if (sport > dport) {
			return [NSString stringWithFormat:@"%@:%d -> %@:%d",
				[newPacket valueForKey:@"ipSource"], sport,
				[newPacket valueForKey:@"ipDestination"], dport
			];
		} else {
			return [NSString stringWithFormat:@"%@:%d -> %@:%d",
				[newPacket valueForKey:@"ipDestination"], dport,
				[newPacket valueForKey:@"ipSource"], sport
			];
		}
	}
	return nil;
}

- (id)initWithPacket:(NSObject<Dissector> *)newPacket usingSubAggregates:(NSArray *)subAggregates
{
	self = [super initWithPacket:newPacket usingSubAggregates:subAggregates];
	if (self) {
		firstPacket = [newPacket retain];
	}
	return self;
}

- (NSString *)sourceString
{
	return [firstPacket valueForKey:@"ipSource"];
}

- (NSString *)destinationString
{
	return [firstPacket valueForKey:@"ipDestination"];
}

- (NSString *)typeString
{
	return @"Conversation";
}

- (NSString *)timeString
{
	return [NSString stringWithFormat:@"%f sec.", [(NSDate *)[lastPacket valueForKey:@"timestamp"]
			timeIntervalSinceDate:[firstPacket valueForKey:@"timestamp"]
		]
	];
}

- (NSString *)infoString
{
	return [firstPacket infoString];
}

- (id)flagsString
{
	NSMutableAttributedString *tempString
		= [[[NSMutableAttributedString alloc] initWithAttributedString:[lastPacket flagsString] ] autorelease];

	if ( [[firstPacket valueForKey:@"ipSource"] isEqualToString:[lastPacket valueForKey:@"ipSource"] ] ) {
		[tempString insertAttributedString:[[[NSAttributedString alloc] initWithString:@"<"] autorelease] atIndex:0];
		[tempString insertAttributedString:[[[NSAttributedString alloc] initWithString:@" "] autorelease] atIndex:9];
	} else {
		[tempString insertAttributedString:[[[NSAttributedString alloc] initWithString:@" "] autorelease] atIndex:0];
		[tempString insertAttributedString:[[[NSAttributedString alloc] initWithString:@">"] autorelease] atIndex:9];
	}

	return tempString;
}

- (NSData *)payloadData
{
	NSMutableData *tempData = [NSMutableData data];
	NSEnumerator *en = [packetArray objectEnumerator];
	id tempPacket;
	while ( tempPacket=[en nextObject] ) {
		[tempData appendData:[tempPacket valueForKey:@"payloadData"] ];
	}
	return [tempData copy];
}

@end
