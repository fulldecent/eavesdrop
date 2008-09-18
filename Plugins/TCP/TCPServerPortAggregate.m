//
//  TCPServerPortAggregate.m
//  Eavesdrop
//
//  Created by Eric Baur on 10/15/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "TCPServerPortAggregate.h"

static TCPServerPortAggregateDefaults *defaults;
static NSDictionary *serverPorts;

@implementation TCPServerPortAggregate

+ (void)initialize
{
	DEBUG( @"initialize" );
	[TCPServerPortAggregate resetServerPortsFromDefaults];
}

+ (void)resetServerPortsFromDefaults
{
	ENTRY;
	if (!defaults)
		defaults = [[Plugin pluginDefaultsForClass:[self class] ] retain];
		
	NSEnumerator *en = [[defaults portsArray] objectEnumerator];

	NSDictionary *tempDict;
	NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
	while ( tempDict=[en nextObject] ) {
		if ( [[tempDict objectForKey:@"enabled"] boolValue] )
			[newDict setObject:tempDict forKey:[tempDict objectForKey:@"port"] ];
	}
	[serverPorts release];
	serverPorts = [[newDict copy] retain];
}

+ (NSString *)aggregateIdentifierForPacket:(NSObject<Dissector> *)newPacket
{
	if ( [newPacket respondsToSelector:@selector(tcpSourcePort)] ) {
		id sport = [newPacket valueForKey:@"tcpSourcePort"];
		id dport = [newPacket valueForKey:@"tcpDestinationPort"];

		id serverPort = [serverPorts objectForKey:[sport stringValue] ];
		if (serverPort)
			return [sport stringValue];
			
		serverPort = [serverPorts objectForKey:[dport stringValue] ];
		if (serverPort)
			return [dport stringValue];
					
		if (!serverPort && [[defaults valueForKey:@"useLowPort"] boolValue] ) {
			if ([sport intValue] > [dport intValue]) {
				return [dport stringValue];
			} else {
				return [sport stringValue];
			}
		}
	}
	return nil;
}

- (NSString *)typeString
{
	return @"TCP Server Port";
}

- (NSString *)infoString
{
	return [[serverPorts valueForKey:identifier] valueForKey:@"name"];
}

- (NSString *)descriptionString
{
	return [[serverPorts valueForKey:identifier] valueForKey:@"description"];
}

@end
