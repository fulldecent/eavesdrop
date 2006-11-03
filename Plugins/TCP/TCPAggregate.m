//
//  TCPAggregate.m
//  Eavesdrop
//
//  Created by Eric Baur on 6/18/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "TCPAggregate.h"


@implementation TCPAggregate

static NSView *staticPayloadTextView;
static NSView *staticPayloadImageView;

+ (void)initialize
{
	ENTRY( @"initialize" );
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
		//isTCP = [firstPacket respondsToSelector:@selector(tcpSourcePort)];
	}
	return self;
}

- (NSString *)sourceString
{
	return [NSString stringWithFormat:@"Client: %@", [firstPacket valueForKey:@"ipSource"] ];
}

- (NSString *)destinationString
{
	return [NSString stringWithFormat:@"Server: %@", [firstPacket valueForKey:@"ipDestination"] ];
}

- (NSString *)typeString
{
	return @"TCP Conversation";
}

- (NSString *)timeString
{
	return [NSString stringWithFormat:@"%f sec.", [(NSDate *)[lastPacket valueForKey:@"timestamp"]
			timeIntervalSinceDate:[firstPacket valueForKey:@"timestamp"]
		]
	];
}

- (NSString *)flagsString
{
	return [lastPacket flagsString];
}

- (NSString *)payloadString
{
	INFO( [lastPacket valueForKey:@"ethernetPayloadData"] );
	return @"nothing for now";
}


#pragma mark -
#pragma mark View methods

- (NSView *)payloadTextView
{
	ENTRY( @"payloadTextView" );
	if (!staticPayloadTextView) {
		if ( ![NSBundle loadNibNamed:@"TCPAggregate" owner:self] ) {
			ERROR( @"failed to load TCPAggregate nib" );
		} else {
			staticPayloadTextView = [tcpPayloadTextView retain];
		}
	}
	//remove this:
	[self payloadString];
	//end "remove this"
	return staticPayloadTextView;
}

- (NSView *)payloadImageView
{
	ENTRY( @"payloadImageView" );
	if (!staticPayloadImageView) {
		if ( ![NSBundle loadNibNamed:@"TCPAggregate" owner:self] ) {
			ERROR( @"failed to load TCPAggregate nib" );
		} else {
			staticPayloadImageView = [tcpPayloadImageView retain];
		}
	}
	return staticPayloadImageView;
}


@end
