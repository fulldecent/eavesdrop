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
	ENTRY;
	packetCount = 0;
}

#pragma mark -
#pragma mark Protocol Class methods

+ (BOOL)canDecodePacket:(NSObject<Dissector> *)testPacket
{
	return YES;
}

//this is only called for Packet, not for child dissectors
- (id)initWithHeaderData:(NSData *)header packetData:(NSData *)packet
{
	self = [super initWithHeaderData:header packetData:packet];
	if (self) {
		packetNumber = ++packetCount;
		headerData = [header retain];
		payloadData = [packet retain];
	}
	return self;
}

#pragma mark -
#pragma mark Packet methods

- (NSData *)packetHeaderData
{
	return headerData;
}

- (NSData *)packetPayloadData
{
	return payloadData;
}

- (NSNumber *)number
{
	return [NSNumber numberWithInt:packetNumber];
}

- (NSNumber *)captureLength
{
	struct pcap_pkthdr *header;
	header = (struct pcap_pkthdr*)[headerData bytes];
    return [NSNumber numberWithInt:(int)(header->caplen) ];
}

- (NSNumber *)length 
{
	struct pcap_pkthdr *header;
	header = (struct pcap_pkthdr*)[headerData bytes];
    return [NSNumber numberWithInt:(int)(header->len) ];
}

- (NSDate *)timestamp 
{
	struct pcap_pkthdr *header;
	header = (struct pcap_pkthdr*)[headerData bytes];
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
