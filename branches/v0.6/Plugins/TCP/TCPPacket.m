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
			WARNING( @"data_size less than zero, adjusting sizes" );
			data_size = 0;
			if ( [tempData length] < sizeof(struct tcphdr) ) {
				ERROR( @"packet too short for entire header to be present!" );
				header_size = 0;	// this may cause more trouble than it's worth
			} else {
				header_size = [tempData length];	// may cause issues if options are at the end
			}
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

- (id)typeString
{
	return @"-TCP-";
}

- (id)infoString
{
	return [NSString stringWithFormat:@"%@ -> %@", [self tcpSourcePort], [self tcpDestinationPort] ] ;
}

- (id)flagsString
{
	if (flagString)
		return flagString;
	const struct tcphdr *tcp = (struct tcphdr*)( [headerData bytes] );

	NSMutableAttributedString *tempString = [[[NSMutableAttributedString alloc]
		initWithString:@"--------"//@"        "
		attributes:[NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName ]
	] autorelease];

	PluginDefaults *defaults = [Plugin pluginDefaultsForClassName:[self className] ];

	if (tcp->th_flags & TH_FIN)
		[tempString replaceCharactersInRange:NSMakeRange(0,1) withString:@"F"];
	if (tcp->th_flags & TH_SYN)
		[tempString replaceCharactersInRange:NSMakeRange(1,1) withString:@"S"];
	if (tcp->th_flags & TH_RST)
		[tempString replaceCharactersInRange:NSMakeRange(2,1) withString:@"R"];
	if (tcp->th_flags & TH_PUSH)
		[tempString replaceCharactersInRange:NSMakeRange(3,1) withString:@"P"];
	if (tcp->th_flags & TH_ACK)
		[tempString replaceCharactersInRange:NSMakeRange(4,1) withString:@"A"];
	if (tcp->th_flags & TH_URG)
		[tempString replaceCharactersInRange:NSMakeRange(5,1) withString:@"U"];
	if (tcp->th_flags & TH_ECE)
		[tempString replaceCharactersInRange:NSMakeRange(6,1) withString:@"E"];
	if (tcp->th_flags & TH_CWR)
		[tempString replaceCharactersInRange:NSMakeRange(7,1) withString:@"C"];

	NSColor *groupColor = [[defaults valueForKey:@"flagGroupsDictionary"] valueForKey:[tempString mutableString] ];
	if (groupColor) {
		[tempString
			addAttribute:NSForegroundColorAttributeName
			value:groupColor
			range:NSMakeRange(0,8)
		];
	}
	@try {
		//couldn't find a specific one (or config set), so fill in the flags seperately
		if ( !groupColor || [[defaults valueForKey:@"flagsOverlayGroup"] boolValue] ) {	
			NSDictionary *flagsDict = [defaults valueForKey:@"flagsDictionary"];

			if (tcp->th_flags & TH_FIN) {
				[tempString
					addAttribute:NSForegroundColorAttributeName
					value:[[flagsDict valueForKey:@"FIN"] valueForKey:@"color"]
					range:NSMakeRange(0,1)
				];
			}
			if (tcp->th_flags & TH_SYN) {
				[tempString
					addAttribute:NSForegroundColorAttributeName
					value:[[flagsDict valueForKey:@"SYN"] valueForKey:@"color"]
					range:NSMakeRange(1,1)
				];
			}
			if (tcp->th_flags & TH_RST) {
				[tempString
					addAttribute:NSForegroundColorAttributeName
					value:[[flagsDict valueForKey:@"RST"] valueForKey:@"color"]
					range:NSMakeRange(2,1)
				];
			}
			if (tcp->th_flags & TH_PUSH) {
				[tempString
					addAttribute:NSForegroundColorAttributeName
					value:[[flagsDict valueForKey:@"PUSH"] valueForKey:@"color"]
					range:NSMakeRange(3,1)
				];
			}
			if (tcp->th_flags & TH_ACK) {
				[tempString
					addAttribute:NSForegroundColorAttributeName
					value:[[flagsDict valueForKey:@"ACK"] valueForKey:@"color"]
					range:NSMakeRange(4,1)
				];
			}
			if (tcp->th_flags & TH_URG) {
				[tempString
					addAttribute:NSForegroundColorAttributeName
					value:[[flagsDict valueForKey:@"URG"] valueForKey:@"color"]
					range:NSMakeRange(5,1)
				];
			}
			if (tcp->th_flags & TH_ECE) {
				[tempString
					addAttribute:NSForegroundColorAttributeName
					value:[[flagsDict valueForKey:@"ECE"] valueForKey:@"color"]
					range:NSMakeRange(6,1)
				];
			}
			if (tcp->th_flags & TH_CWR) {
				[tempString
					addAttribute:NSForegroundColorAttributeName
					value:[[flagsDict valueForKey:@"CWR"] valueForKey:@"color"]
					range:NSMakeRange(7,1)
				];
			}
		}
	}
	@catch (NSException *exception) {
		WARNING1( @"Exception caught: %@ (flagsDict->{flag}->color may not be defined)", [exception description] );
	}

	flagString = [[tempString copy] retain];
	return flagString;
}

- (id)descriptionString
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
