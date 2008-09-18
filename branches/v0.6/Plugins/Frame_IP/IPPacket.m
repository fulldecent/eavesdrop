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
	const struct ether_header *ether_header = (struct ether_header*)( [testPacket headerBytes] );
	if ( testPacket && 8==ether_header->ether_type ) { //ETHERTYPE_IP should work here, I think... but it doesn't
		return YES;
	}
	return NO;
}

+ (void)initialize
{
	ENTRY;
	protocolsArray = [[NSArray arrayWithContentsOfFile:
		[[NSBundle bundleForClass:[self class]] pathForResource:@"IP_Protocols" ofType:@"plist"]
	] retain];
}

#pragma mark -
#pragma mark Setup method

- (id)initFromParent:(id)parentPacket
{
	self = [super initFromParent:parentPacket];
	if (self) {		///what am I doing here?
		NSData *tempData = [parentPacket payloadData];
		int header_size = sizeof( struct ip );
		int data_size = [tempData length] - header_size;

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
#pragma mark Instance methods

- (NSString *)ipDestination 
{
	return [self destinationString];
}

- (NSNumber *)ipProtocol 
{
	const struct ip *ip = (struct ip*)( [headerData bytes] );
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

- (NSData *)ipHeaderData
{
	return headerData;
}

- (NSData *)ipPayloadData
{
	return payloadData;
}

- (int)ipHeaderLength
{
	return sizeof( struct ether_header );
}

- (int)ipPayloadLength
{
	return [payloadData length];
}

#pragma mark -
#pragma mark Protocol instance methods

- (NSData *)payloadData
{
	return payloadData;
/*
    NSData * tmpValue;
	    
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
	return tmpValue;
*/
}

- (NSString *)sourceString
{
	const struct ip *ip = (struct ip*)( [headerData bytes] );
	return [NSString stringWithCString:inet_ntoa(ip->ip_src)];
}

- (NSString *)destinationString
{
	const struct ip *ip = (struct ip*)( [headerData bytes] );
	return [NSString stringWithCString:inet_ntoa(ip->ip_dst)];
}

- (NSString *)typeString
{
	const struct ip *ip = (struct ip*)( [headerData bytes] );
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

@end
