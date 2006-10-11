//
//  Packet.m
//  Eavesdrop
//
//  Created by Eric Baur on 5/28/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "Packet.h"


@implementation Packet

static int packetCount;

+ (void)initialize
{
	ENTRY( @"initialize" );
	packetCount = 0;
}

#pragma mark -
#pragma mark Protocol Class methods

+ (BOOL)canDecodePacket:(NSObject<Dissector> *)testPacket
{
	return YES;
}

/*
+ (BOOL)canDecodePayloadData:(NSData *)payload withHeaderData:(NSData *)header fromPacketData:(NSData *)packet;
{
	return YES;
}
*/

- (id)initWithHeaderData:(NSData *)header packetData:(NSData *)packet
{
	self = [super initWithHeaderData:header packetData:packet];
	if (self) {
		packetNumber = ++packetCount;
	}
	return self;
}

#pragma mark -
#pragma mark Packet methods

- (NSNumber *)number
{
	return [NSNumber numberWithInt:packetNumber];
}

- (NSNumber *)captureLength
{
	struct pcap_pkthdr *header;
	header = (struct pcap_pkthdr*)[self headerBytes];
    return [NSNumber numberWithInt:(int)(header->caplen) ];
}

- (NSNumber *)length 
{
	struct pcap_pkthdr *header;
	header = (struct pcap_pkthdr*)[self headerBytes];
    return [NSNumber numberWithInt:(int)(header->len) ];
}

- (NSDate *)timestamp 
{
	struct pcap_pkthdr *header;
	header = (struct pcap_pkthdr*)[self headerBytes];
	double tempDouble = header->ts.tv_sec + header->ts.tv_usec*1.0e-6;
    return [NSDate dateWithTimeIntervalSince1970:tempDouble];
}

- (NSString *)timeString
{
	return [[self timestamp] descriptionWithCalendarFormat:@"%H:%M:%S.%F" timeZone:nil locale:nil];
}	

- (NSString *)protocolString
{
	return @"packet";
}

@end
