//
//  TCPPacket.m
//  Eavesdrop
//
//  Created by Eric Baur on 6/9/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "TCPPacket.h"


@implementation TCPPacket

+ (BOOL)canDecodePacket:(NSObject<Dissector> *)testPacket
{
	if ( [[testPacket valueForKey:@"ipProtocol"] isEqualTo:[NSNumber numberWithInt:6]] )
		return YES;
	else
		return NO;

}

- (id)initFromParent:(id)parentPacket
{
	self = [super initFromParent:parentPacket];
	if (self) {
		NSData *tempData = [parentPacket payloadData];
		const struct tcphdr *tcp = (struct tcphdr*)( [tempData bytes] );

		int header_size = (4*tcp->th_off); //this is the real size of the header (including options)
		int data_size = [tempData length] - header_size;

		if ( data_size < 0 ) {
			WARNING( @"data_size less than zero, using zero" );
			data_size = 0;
		}

		// this does not take TCP options into account, so it's too small!
		char bufferHeader[ header_size ];
		[tempData getBytes:&bufferHeader range:NSMakeRange( 0, header_size )];
		headerData = [[NSData dataWithBytes:bufferHeader length:header_size ] retain];

		// this does not take TCP options into account, so it's too large!
		char bufferPayload[ data_size ];
		[tempData getBytes:&bufferPayload range:NSMakeRange( header_size, data_size )];
		payloadData = [[NSData dataWithBytes:bufferPayload length:data_size ] retain];
	}
	return self;
}

#pragma mark -
#pragma mark Accessor methods

- (NSNumber *)tcpAcknowledgement
{
	const struct tcphdr *tcp = (struct tcphdr*)( [headerData bytes] );
    return [NSNumber numberWithUnsignedLongLong:tcp->th_ack];
}

- (NSString *)tcpFlags 
{
	return [self flagsString];
}

- (NSNumber *)tcpDestinationPort 
{
	const struct tcphdr *tcp = (struct tcphdr*)( [headerData bytes] );
    return [NSNumber numberWithInt:ntohs(tcp->th_dport)];
}

- (NSNumber *)tcpSequence 
{
	const struct tcphdr *tcp = (struct tcphdr*)( [headerData bytes] );
    return [NSNumber numberWithUnsignedLongLong:tcp->th_seq];
}

- (NSNumber *)tcpSourcePort 
{
	const struct tcphdr *tcp = (struct tcphdr*)( [headerData bytes] );
    return [NSNumber numberWithInt:ntohs(tcp->th_sport)];
}

- (NSNumber *)tcpWindow 
{
	const struct tcphdr *tcp = (struct tcphdr*)( [headerData bytes] );
    return [NSNumber numberWithInt:tcp->th_win];
}

- (int)tcpHeaderLength
{
	return [headerData length];
}

- (int)tcpPayloadLength 
{
	return [payloadData length];;
}

- (NSData *)tcpHeaderData
{
	return headerData;
}

- (NSData *)tcpPayloadData
{
	return payloadData;
}

#pragma mark -
#pragma mark Protocol instance methods

//sourceString supplied by IPPacket
//destinationString supplied by IPPacket

- (NSString *)typeString
{
	return @"-TCP-";
}

- (NSString *)infoString
{
	return [NSString stringWithFormat:@"%@ -> %@", [self tcpSourcePort], [self tcpDestinationPort] ] ;
}

- (NSString *)flagsString
{
	const struct tcphdr *tcp = (struct tcphdr*)( [headerData bytes] );

	char flags[] = "--------";
	/* -- Record the flags in use -- */
	if (tcp->th_flags & TH_FIN)
		flags[0] = 'F';
	if (tcp->th_flags & TH_SYN)
		flags[1] = 'S';
	if (tcp->th_flags & TH_RST)
		flags[2] = 'R';
	if (tcp->th_flags & TH_PUSH)
		flags[3] = 'P';
	if (tcp->th_flags & TH_ACK)
		flags[4] = 'A';
	if (tcp->th_flags & TH_URG)
		flags[5] = 'U';
	if (tcp->th_flags & TH_ECE)
		flags[6] = 'E';
	if (tcp->th_flags & TH_CWR)
		flags[7] = 'C';

	return [NSString stringWithCString:flags];
}

- (NSString *)descriptionString
{
	return @"I need to fill this in...";
}

- (NSString *)protocolString
{
	return @"TCP";
}

- (NSArray *)payloadViewArray
{
	ENTRY( @"payloadViewArray" );
	return [NSArray array];
}

@end
