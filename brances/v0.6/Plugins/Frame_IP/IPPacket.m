//
//  PacketEthernetIP.m
//  Eavesdrop
//
//  Created by Eric Baur on 6/1/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "IPPacket.h"


@implementation IPPacket

static NSArray *protocolsArray;

#pragma mark -
#pragma mark Protocol Class methods

+ (BOOL)canDecodePacket:(NSObject<Dissector> *)testPacket
{
	const struct ether_header *ether_header = (struct ether_header*)( [testPacket packetBytes] );
	if ( testPacket && ETHERTYPE_IP==ether_header->ether_type ) {
		return YES;
	}
	return NO;
}

/*
+ (BOOL)canDecodePayloadData:(NSData *)payload withHeaderData:(NSData *)header fromPacketData:(NSData *)packet
{
	//ENTRY( @"+canDecodePayloadData:withHeaderData:fromPacketData:" );
	const struct ether_header *ether_header = (struct ether_header*)( [packet bytes] );
	if ( packet && ETHERTYPE_IP==ether_header->ether_type ) {
		return YES;
	}
	return NO;
}
*/

+ (void)initialize
{
	ENTRY( @"initialize" );	
	protocolsArray = [[NSArray arrayWithContentsOfFile:
		[[NSBundle bundleForClass:[self class]] pathForResource:@"IP_Protocols" ofType:@"plist"]
	] retain];
}

#pragma mark -
#pragma mark Instance methods

- (NSString *)ipDestination 
{
	return [self destinationString];
}

- (NSNumber *)ipProtocol 
{
	const struct ip *ip;
	ip = (struct ip*)(
		[self packetBytes] + sizeof(struct ether_header)
	);
	return [NSNumber numberWithInt:ip->ip_p];
}

- (NSString *)ipProtocolString
{
	return [self typeString];
}

- (NSString *)ipSource 
{
	return [self sourceString];
}

#pragma mark -
#pragma mark Protocol instance methods

- (NSData *)payloadData
{
    NSData * tmpValue;
/*    
	struct pcap_pkthdr *header = (struct pcap_pkthdr*)[self headerBytes];
	u_char *packet = (u_char*)[self packetBytes];
	
	const struct tcphdr *tcp;
	const char *payload;
	unsigned int size_ethernet = sizeof(struct ether_header);
	unsigned int size_ip = sizeof(struct ip);
	unsigned int payload_size;
	
	tcp = (struct tcphdr*)(packet + size_ethernet + size_ip);

	//need to find a bettery way to do this (no access to packetheader)
	if ( header->caplen > (size_ethernet+size_ip+(4*tcp->th_off)) && header->caplen > 60 ) {
		payload_size = header->caplen - size_ethernet - size_ip - (4*tcp->th_off);
		//why is the next line a warning ("differ in sign")
		payload = (u_char *)(packet + size_ethernet + size_ip + (4*tcp->th_off));
		tmpValue = [NSData dataWithBytes:payload length:payload_size];
	} else {
		tmpValue = [NSData data];	//no payload, blank data (why not nil?)
	}
*/
	return tmpValue;
}

- (NSString *)sourceString
{
	const struct ip *ip;
	ip = (struct ip*)(
		[self packetBytes] + sizeof(struct ether_header)
	);
	return [NSString stringWithCString:inet_ntoa(ip->ip_src)];
}

- (NSString *)destinationString
{
	const struct ip *ip;
	ip = (struct ip*)(
		[self packetBytes] + sizeof(struct ether_header)
	);
	return [NSString stringWithCString:inet_ntoa(ip->ip_dst)];
}

- (NSString *)typeString
{
	const struct ip *ip;
	ip = (struct ip*)(
		[self packetBytes] + sizeof(struct ether_header)
	);
	NSString *tempString = [[protocolsArray objectAtIndex:ip->ip_p] valueForKey:@"Keyword"];
	if (tempString)
		return tempString;
	else
		return @"IP";
}

- (NSString *)infoString
{
	return @"?";
}

- (NSString *)descriptionString
{
	return @"???";
}

- (NSString *)protocolString
{
	return @"IP";
}

- (NSDictionary *)keyNames
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		@"Destination IP Address",	@"ipDestination",
		@"IP Protocol",				@"ipProtocol",
		@"IP Protocol Name",		@"ipProtocolString",
		@"Source IP Address",		@"ipSource",
		nil
	];
}


@end
