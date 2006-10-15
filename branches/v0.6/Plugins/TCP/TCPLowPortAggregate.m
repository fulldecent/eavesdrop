//
//  TCPLowPortAggregate.m
//  Eavesdrop
//
//  Created by Eric Baur on 10/14/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "TCPLowPortAggregate.h"

@implementation TCPLowPortAggregate

+ (NSString *)aggregateIdentifierForPacket:(NSObject<Dissector> *)newPacket
{
	if ( [newPacket respondsToSelector:@selector(tcpSourcePort)] ) {
		int sport = [[newPacket valueForKey:@"tcpSourcePort"] intValue];
		int dport = [[newPacket valueForKey:@"tcpDestinationPort"] intValue];
		if (sport > dport) {
			return [NSString stringWithFormat:@"%d", dport];
		} else {
			return [NSString stringWithFormat:@"%d", sport];
		}
	}
	return nil;
}

- (NSString *)typeString
{
	return @"TCP Low Port";
}

- (NSString *)infoString
{
	return identifier;
}

@end
