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

/*
+ (BOOL)canDecodePayloadData:(NSData *)payload withHeaderData:(NSData *)header fromPacketData:(NSData *)packet
{
	const struct ip *ip;
	ip = (struct ip*)(
		[packet bytes] + sizeof(struct ether_header)
	);
	if ( 6==ip->ip_p )
		return YES;
	else
		return NO;
}
*/

- (NSNumber *)tcpAcknowledgement
{
	const struct tcphdr *tcp;
	tcp = (struct tcphdr*)(
		[self packetBytes] + sizeof(struct ether_header) + sizeof(struct ip)
	);
    return [NSNumber numberWithUnsignedLongLong:tcp->th_ack];
}

- (NSString *)tcpFlags 
{
	return [self flagsString];
}

- (NSNumber *)tcpDestinationPort 
{
	const struct tcphdr *tcp;
	tcp = (struct tcphdr*)(
		[self packetBytes] + sizeof(struct ether_header) + sizeof(struct ip)
	);
    return [NSNumber numberWithInt:ntohs(tcp->th_dport)];
}

- (NSNumber *)tcpSequence 
{
	const struct tcphdr *tcp;
	tcp = (struct tcphdr*)(
		[self packetBytes] + sizeof(struct ether_header) + sizeof(struct ip)
	);
    return [NSNumber numberWithUnsignedLongLong:tcp->th_seq];
}

- (NSNumber *)tcpSourcePort 
{
	const struct tcphdr *tcp;
	tcp = (struct tcphdr*)(
		[self packetBytes] + sizeof(struct ether_header) + sizeof(struct ip)
	);
    return [NSNumber numberWithInt:ntohs(tcp->th_sport)];
}

- (NSNumber *)tcpWindow 
{
	const struct tcphdr *tcp;
	tcp = (struct tcphdr*)(
		[self packetBytes] + sizeof(struct ether_header) + sizeof(struct ip)
	);
    return [NSNumber numberWithInt:tcp->th_win];
}
#pragma mark -
#pragma mark Protocol methods

- (NSNumber *)payloadLength 
{ //STUB
	return nil;
}

- (NSString *)payloadString 
{ //STUB
    return nil;
}


#pragma mark -
#pragma mark Protocol instance methods

- (NSData *)payloadData
{
    NSData * tmpValue;
    
	struct pcap_pkthdr *header = (struct pcap_pkthdr*)[self headerBytes];
	u_char *packet = (u_char*)[self packetBytes];
	
	const struct tcphdr *tcp;
	const char *payload;
	unsigned int size_ethernet = sizeof(struct ether_header);
	unsigned int size_ip = sizeof(struct ip);
	unsigned int payload_size;
	
	tcp = (struct tcphdr*)(packet + size_ethernet + size_ip);

	//...this shouldn't be necessary!
	if ( ! (header && packet) )
		return nil;

	if ( header->caplen > (size_ethernet+size_ip+(4*tcp->th_off)) && header->caplen > 60 ) {
		payload_size = header->caplen - size_ethernet - size_ip - (4*tcp->th_off);
		//why is the next line a warning ("differ in sign") when it is u_char?
		payload = (char *)(packet + size_ethernet + size_ip + (4*tcp->th_off));
		tmpValue = [NSData dataWithBytes:payload length:payload_size];
	} else {
		tmpValue = [NSData data];	//no payload, blank data (why not nil?)
	}
	return tmpValue;
}

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
	const struct tcphdr *tcp;
	tcp = (struct tcphdr*)(
		[self packetBytes] + sizeof(struct ether_header) + sizeof(struct ip)
	);

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
