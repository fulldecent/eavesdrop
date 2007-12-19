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
	//TODO: honestly look at packet to see if we can decode it
	return YES;
}

#pragma mark -
#pragma mark Setup methods

- (id)initFromParent:(id)parentPacket
{
	self = [super initFromParent:parentPacket];
	if (self) {
		NSData *tempData = [parentPacket payloadData];
		int header_size = sizeof( struct ether_header );
		int data_size = [tempData length] - header_size;
		if ( data_size < 0 ) {
			WARNING( @"ethernet payload less than zero (will use full packet length instead)" );
			data_size = [tempData length];
		}

		char bufferHeader[ header_size ];
		[tempData getBytes:&bufferHeader range:NSMakeRange( 0, header_size )];
		headerData = [[NSData dataWithBytes:bufferHeader length:header_size ] retain];

		char bufferPayload[ data_size ];
		[tempData getBytes:&bufferPayload range:NSMakeRange( header_size, data_size )];
		payloadData = [[NSData dataWithBytes:bufferPayload length:data_size ] retain];
	}
	return self;
}

#pragma mark -
#pragma mark Accessor methods

- (NSString *)ethernetDestination
{
	//TODO: fix address display (0 -> 00)
	return [self destinationString];
}

- (NSNumber *)ethernetProtocol
{
	const struct ether_header *ether_header = (struct ether_header*)( [headerData bytes] );
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
#pragma mark Plugin Protocol Instance methods

- (NSString *)sourceString
{	//ethernetSource
	const struct ether_header *ether_header = (struct ether_header*)( [headerData bytes] );
	const struct ether_addr *ether_addr = (struct ether_addr*)(ether_header->ether_shost);
	return [NSString stringWithCString:ether_ntoa(ether_addr)];
}

- (NSString *)destinationString
{	//ethernetDestination
	const struct ether_header *ether_header = (struct ether_header*)( [headerData bytes] );
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

	const struct ether_header *ether_header = (struct ether_header*)( [headerData bytes] );	
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

#pragma mark -
#pragma mark Dissector Protocol Instance methods

- (NSData *)ethernetHeaderData
{
	return headerData;
}

- (NSData *)ethernetPayloadData
{
	return payloadData;
}

- (int)ethernetHeaderLength
{
	return sizeof( struct ether_header );
}

- (int)ethernetPayloadLength
{
	return [payloadData length];
}

@end
