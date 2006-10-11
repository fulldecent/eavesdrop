//
//  PacketEthernet.m
//  Eavesdrop
//
//  Created by Eric Baur on 6/1/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "EthernetPacket.h"

@implementation EthernetPacket

#pragma mark -
#pragma mark Protocol Class methods

+ (BOOL)canDecodePacket:(NSObject<Dissector> *)testPacket
{
	return YES;
}

/*
+ (BOOL)canDecodePayloadData:(NSData *)payload withHeaderData:(NSData *)header fromPacketData:(NSData *)packet
{
	//way over simplistic
	return YES;
}
*/

#pragma mark -
#pragma mark Accessor methods

- (NSString *)ethernetDestination
{
	return [self destinationString];
}

- (NSNumber *)ethernetProtocol
{
	const struct ether_header *ether_header = (struct ether_header*)( [self packetBytes] );
	return [NSNumber numberWithShort:(unsigned short)(ether_header->ether_type)];
}

- (NSString *)ethernetProtocolString
{
	return [self infoString];
}

- (NSString *)ethernetSource
{
	return [self sourceString];
}

#pragma mark -
#pragma mark Protocol Instance methods

- (NSString *)sourceString
{	//ethernetSource
	const struct ether_header *ether_header = (struct ether_header*)( [self packetBytes] );
	const struct ether_addr *ether_addr = (struct ether_addr*)(ether_header->ether_shost);
	return [NSString stringWithCString:ether_ntoa(ether_addr)];
}

- (NSString *)destinationString
{	//ethernetDestination
	const struct ether_header *ether_header = (struct ether_header*)( [self packetBytes] );
	const struct ether_addr *ether_addr = (struct ether_addr*)(ether_header->ether_dhost);
	return [NSString stringWithCString:ether_ntoa(ether_addr)];
}

- (NSString *)typeString
{
	return @"ethernet";
}

- (NSString *)infoString
{	//ethernetProtocolString
    NSString * tmpValue;

	const struct ether_header *ether_header = (struct ether_header*)( [self packetBytes] );	
	switch ( (unsigned short)(ether_header->ether_type) ) {
		case ETHERTYPE_PUP:		tmpValue = @"PUP";		break;
		case ETHERTYPE_IP:		tmpValue = @"IP";		break;
		case ETHERTYPE_ARP:		tmpValue = @"ARP";		break;
		case ETHERTYPE_REVARP:	tmpValue = @"rARP";		break;
		case ETHERTYPE_VLAN:	tmpValue = @"VLAN";		break;
		case ETHERTYPE_IPV6:	tmpValue = @"IPV6";		break;
		case ETHERTYPE_LOOPBACK:tmpValue = @"LO";		break;
		case ETHERTYPE_TRAIL:	tmpValue = @"TRAIL";	break;
		case ETHERTYPE_NTRAILER:tmpValue = @"NTRAILER";	break;
		default:
			tmpValue = [NSString stringWithFormat:@"unknown (%d)", (unsigned short)(ether_header->ether_type) ];
	}
	
    return tmpValue;
}

- (NSString *)descriptionString
{
	return @"no sub-dissector found";
}

- (NSString *)protocolString
{
	return @"Ethernet";
}

@end
