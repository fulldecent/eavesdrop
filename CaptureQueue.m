//
//  CaptureQueue.m
//  Eavesdrop
//
//  Created by Eric Baur on Sun Aug 01 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

#import "CaptureQueue.h"

@implementation CaptureQueue

+ (void)queueThreadWithSettings:(NSDictionary *)settings
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSConnection *serverConnection;
	CaptureQueue *serverObject;

	serverObject = [self
		queueWithController:[settings objectForKey:@"CaptureController"]
	];

	serverConnection = [NSConnection defaultConnection];
	[serverConnection setRootObject:serverObject];

	if ([serverConnection registerName:[settings objectForKey:@"QueueIdentifier"]] == NO) {
		NSLog( @"DistributedObject - registered name %@ taken.", [settings objectForKey:@"QueueIdentifier"] );
		return;
	}

	[NSThread
		detachNewThreadSelector:@selector(readPackets)
		toTarget:serverObject
		withObject:nil
	];

	[[NSRunLoop currentRunLoop] run];
	[pool release];
	
	return;
}

+ (id)queueWithController:(id)aController
{
	return [[[CaptureQueue alloc] initWithController:aController] autorelease];
}

- (id)initWithController:(id)aController
{
	self = [super init];
	if (self) {
		packetQueue = [[NSMutableArray array] retain];
		headerQueue = [[NSMutableArray array] retain];
		queueLock = [[NSConditionLock alloc] initWithCondition:NO_DATA];
		additionsLock = [[NSLock alloc] init];
		
		conversations = [[NSMutableDictionary dictionary] retain];
		additions = [[NSMutableArray array] retain];
		
		[aController
			performSelectorOnMainThread:@selector(setPacketQueueAndLock:)
			withObject:[NSDictionary dictionaryWithObjectsAndKeys:
				additions,		@"additions",
				additionsLock,	@"lock",
				nil
			]
			waitUntilDone:NO
		];
		
		updateNeeded = NO;
		dataQueued = NO;
	}
	return self;
}

- (oneway void)addPacket:(NSData *)packetData withHeader:(NSData *)headerData
{
	[packetData retain];
	[headerData retain];
	[queueLock lock];
	[packetQueue addObject:packetData];
	[headerQueue addObject:headerData];
	[queueLock unlockWithCondition:HAS_DATA];
}

- (oneway void)addPacket:(NSDictionary *)packetDict
{
	[packetDict retain];
	[queueLock lock];
	[packetQueue addObject:packetDict];
	[queueLock unlockWithCondition:HAS_DATA];
}

- (void)readPackets
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
	BOOL read = YES;
	NSData *tempPacket;
	NSData *tempHeader;
	while (read) {
		[queueLock lockWhenCondition:HAS_DATA];
		tempPacket = [packetQueue objectAtIndex:0];
		tempHeader = [headerQueue objectAtIndex:0];
		[packetQueue removeObjectAtIndex:0];
		[headerQueue removeObjectAtIndex:0];
		if ([packetQueue count]) {
			[queueLock unlockWithCondition:HAS_DATA];
		} else {
			[queueLock unlockWithCondition:NO_DATA];
		}
		[self addPacketDictionary:[self dictionaryFromPacket:tempPacket withHeader:tempHeader] ];
		[tempPacket release];
		[tempHeader release];
	}
	
	[pool release];
}

- (NSDictionary *)dictionaryFromPacket:(NSData *)packetData withHeader:(NSData *)headerData
{
	struct pcap_pkthdr *header;
	u_char *packet;//[ [packetData length] ];
	
	static int count = 1;                   /* Just a counter of how many packets we've had */
	/* Define pointers for packet's attributes */
	const struct sniff_ethernet *ethernet;  /* The ethernet header */
	const struct sniff_ip *ip;              /* The IP header */
	const struct sniff_tcp *tcp;            /* The TCP header */
	const char *payload;					/* The rest of the packet data */
	char flags[] = "--------";
	/* And define the size of the structures we're using */
	int size_ethernet = sizeof(struct sniff_ethernet);
	int size_ip = sizeof(struct sniff_ip);
	//int size_tcp = sizeof(struct sniff_tcp);
	
	packet = (u_char*)[packetData bytes];
	header = (struct pcap_pkthdr*)[headerData bytes];
	
	int payload_size;
	NSData *payloadData;
	
	/* -- Define our packet's attributes -- */
	ethernet = (struct sniff_ethernet*)(packet);  // get this data from tcp->th_off (data offset?)
	ip = (struct sniff_ip*)(packet + size_ethernet);
	tcp = (struct sniff_tcp*)(packet + size_ethernet + size_ip);
	
	if ( header->caplen > (size_ethernet+size_ip+(4*tcp->th_off)) && header->caplen > 60 ) {
		payload_size = header->caplen - size_ethernet - size_ip - (4*tcp->th_off);
		payload = (u_char *)(packet + size_ethernet + size_ip + (4*tcp->th_off));
		payloadData = [NSData dataWithBytes:payload length:payload_size];
	} else {
		payloadData = [NSData data];	//no payload, blank data
	}
	
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
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
		//[NSData dataWithBytes:packet length:header->caplen],@"packet",
		[NSNumber numberWithInt:count],						@"number",
		[NSString stringWithCString:inet_ntoa(ip->ip_src)],	@"source",
		[NSNumber numberWithInt:ntohs(tcp->th_sport)],		@"sport",
		[NSString stringWithCString:inet_ntoa(ip->ip_dst)],	@"destination",
		[NSNumber numberWithInt:ntohs(tcp->th_dport)],		@"dport",
		[NSString stringWithCString:flags],					@"flags",
		[NSNumber numberWithUnsignedLongLong:tcp->th_seq],	@"sequence",
		[NSNumber numberWithUnsignedLongLong:tcp->th_ack],	@"acknowledgement",
		[NSNumber numberWithInt:tcp->th_win],				@"window",
		[NSNumber numberWithInt:header->len],				@"length",
		[NSNumber numberWithDouble:
			header->ts.tv_sec + header->ts.tv_usec*1.0e-6],	@"timestamp",
		payloadData,										@"payload",
		nil
	];

	count++;
}

- (void)addPacketDictionary:(NSDictionary *)packetDict
{
	NSString *packetID = [Conversation
		calculateIDFromSource:  [packetDict objectForKey:@"source"]
		port:					[[packetDict objectForKey:@"sport"] intValue]
		destination:			[packetDict objectForKey:@"destination"]
		port:					[[packetDict objectForKey:@"dport"] intValue]
	];
	
	Conversation *conversation = [conversations objectForKey:packetID];
	if (conversation) {
		[conversation addPacket:packetDict];
		updateNeeded = YES;
	} else {
		conversation = [[Conversation alloc]
			initWithOrderNumber:([conversations count]+1)
			packet:packetDict
		];
		if (conversation) {
			[conversations setObject:conversation forKey:packetID];
			[additionsLock lock];
			[additions addObject:conversation];
			updateNeeded = YES;
			dataQueued = YES;
			[additionsLock unlock];
		}
	}
}

- (void)retreivedAdditions
{
	dataQueued = NO;
	[additions removeAllObjects];
}

- (BOOL)dataQueued
{
	return dataQueued;
}

- (BOOL)updateNeeded
{
	return updateNeeded;
}

- (void)setUpdateNeeded:(BOOL)newState
{
	updateNeeded = newState;
}

- (int)queueDepth
{
	return [packetQueue count];
}

- (oneway void)noMorePackets
{
	//stop capture here - not sure *exactly* what to do
	NSLog( @"No More Packets!  (capture should end, but it probably won't right now)" );
}

- (oneway void)stopCapture
{
	ENTRY(NSLog(@"[CaptureQueue stopCapture]");)
	//NOT SURE WHAT SHOULD BE DONE HERE - if anything...
	//read = NO;
}

@end
