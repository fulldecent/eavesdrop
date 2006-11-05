//
//  CaptureThread.m
//  Eavesdrop
//
//  Created by Eric Baur on 5/27/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "CaptureThread.h"

@implementation CaptureThread

#pragma mark -
#pragma mark Class methods

static NSMutableDictionary *collectors;

+ (void)initialize
{	ENTRY( @"initialize" );
	[CaptureThread sharedCollectorsDictionary];
}

+ (id)sharedCollectorsDictionary
{
	if (!collectors)
		collectors = [[NSMutableDictionary dictionary] retain];
	return collectors;
}

+ (BOOL)setCollector:(id)collector withName:(NSString *)name
{
	if (!collectors)
		collectors = [CaptureThread sharedCollectorsDictionary];
		
	if ([collectors objectForKey:name]) {
		return NO;
	} else {
		[collectors setObject:collector forKey:name];
		return YES;
	}
}

+ (void)removeCollectorWithName:(NSString *)name
{
	if (!collectors)
		return;
	
	[collectors removeObjectForKey:name ];
}

+ (id)collectorWithName:(NSString *)name
{
	if (!collectors)
		return nil;
	return [collectors objectForKey:name];
}

#pragma mark -
#pragma mark Setup methods

- (id)init
{	ENTRY( @"init" );
	self = [super init];
	if (self) {
		capturesPayload = YES;

		filter = @"";
		promiscuous = YES;
		interface = @"en0";
		
		isActive = NO;
		capture_callback = &packetHandler;
	}
	return self;
}

#pragma mark -
#pragma mark Accessor methods

- (NSString *)client
{
	return client;
}

- (void)setClient:(NSString *)newClient
{	ENTRY1( @"setClient:%@", newClient );
	[client release];
	client = [newClient retain];
}

- (NSString *)saveFile
{
	return saveFilename;
}

- (void)setSaveFile:(NSString *)saveFile
{	ENTRY1( @"setSaveFile:%@", saveFile );
	[saveFilename release];
	saveFilename = [saveFile retain];
}

- (NSString *)readFile
{
	return readFilename;
}

- (void)setReadFile:(NSString *)readFile
{	ENTRY1( @"setReadFile:%@", readFile  );
	[readFilename release];
	readFilename = [readFile retain];
}

- (NSString *)captureFilter
{
	return filter;
}

- (void)setCaptureFilter:(NSString *)filterString
{	ENTRY1( @"setCaptureFilter:%@", filterString );
	[filter release];
	filter = [filterString retain];
}

- (NSString *)interface
{
	return interface;
}

- (void)setInterface:(NSString *)newInterface
{	ENTRY1( @"setInterface:%@", newInterface );
	[interface release];
	interface = [newInterface retain];
}

- (BOOL)promiscuous
{
	return promiscuous;
}

- (void)setPromiscuous:(BOOL)promiscuousMode
{	ENTRY( @"setPromiscuous:" );
	promiscuous = promiscuousMode;
}

- (BOOL)capturesPayload
{
	return capturesPayload;
}

- (void)setCapturesPayload:(BOOL)shouldCapture
{	ENTRY( @"setCapturesPayload:" );
	capturesPayload = shouldCapture;
}

- (BOOL)isActive
{
	return isActive;
}

#pragma mark -
#pragma mark Thread methods

- (void)savePackets:(NSArray *)packetsArray
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSThread setThreadPriority:1.0];
	
	ENTRY( @"saveCapture" );
	DEBUG1( @"saving to file: %@", saveFilename );

	pcap_t *saveHandle = pcap_open_dead( DLT_EN10MB, 65535 );
	pcap_dumper_t *dumpHandle = pcap_dump_open( saveHandle, [saveFilename cString] );
	
	[self dumpPackets:packetsArray toHandle:dumpHandle];
	
	EXIT( @"saveCapture" );
	pcap_close( saveHandle );

	[pool release];
	[NSThread exit];
}

- (void)dumpPackets:(NSArray *)packetList toHandle:(pcap_dumper_t *)dumpHandle
{
	NSEnumerator *en = [packetList objectEnumerator];
	id tempPacket;
	int count = 0;
	while ( tempPacket = [en nextObject] ) {
		NSArray *subList = [tempPacket valueForKey:@"packetArray"];
		if ( [subList count] )
			[self dumpPackets:subList toHandle:dumpHandle];
			
		struct pcap_pkthdr *tempHeader = (struct pcap_pkthdr *)[[tempPacket valueForKey:@"packetHeaderData"] bytes];
		u_char *tempPayload = (u_char *)[[tempPacket valueForKey:@"packetPayloadData"] bytes];
		if ( tempHeader && tempPayload ) {
			pcap_dump( (u_char *)dumpHandle, tempHeader, tempPayload );
			count++;
		}
	}
	DEBUG1( @"wrote %@ packets", [NSNumber numberWithInt:count] );
}

- (void)startCapture
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSThread setThreadPriority:1.0];

	ENTRY( @"startCapture" );	
	if (!client) {
		ERROR( @"can't start capture for null client!");
		[pool release];
		return;
	}
	
	DEBUG( @"vending objects" );
	[DOHelpers vendObject:self withName:[self description] local:YES];
	queueProxy = [DOHelpers getProxyWithName:client protocol:@protocol(PacketQueue) host:nil];

	if (!queueProxy) {
		WARNING1( @"failed to get queueProxy for client: %@", client );
		[pool release];
		return;
	}
	DEBUG1( @"set collector with queueProxy: %@", [queueProxy description] );
	[CaptureThread setCollector:queueProxy withName:client ];

	/// start capture setup ///
	
	DEBUG( @" - setting up capture" );
	
	BOOL setupFailed = NO;
	
	char filter_app[ [filter cStringLength] ];
	char dev[ [interface cStringLength] ];
	unsigned int captureSize;

	int size_ethernet   = sizeof( struct ether_header	);
	int size_ip			= sizeof( struct ip );
	int size_tcp		= sizeof( struct tcphdr );
	
	[filter getCString:filter_app];
	[interface getCString:dev];
	
	if (capturesPayload)
		captureSize = 65535;
	else
		captureSize = ( size_ethernet + size_ip + size_tcp );
	
	if (readFilename)
		captureHandle = pcap_open_offline( [readFilename cString], errbuf );
	else
		captureHandle = pcap_open_live( dev, captureSize, promiscuous, 1, errbuf );
		
//	if (saveFilename)
//		saveHandle = pcap_dump //???
		
	if (!captureHandle) {
		ERROR1( @"capture failed: %s", errbuf );
		ERROR2( @"using device:%@ with filter:%@",interface,filter);
		setupFailed = YES;
	}

	pcap_lookupnet(dev, &netp, &maskp, errbuf);
	if( pcap_compile(captureHandle, &fp, filter_app, 0, netp) == -1) {
			ERROR1( @"pcap_compile failed for filter:%s\n", filter_app );
			setupFailed = YES;
	}
	if (pcap_setfilter(captureHandle, &fp) == -1) {
			ERROR( @"pcap_setfilter failed.\n" );
			setupFailed = YES;
	}
	
	if (setupFailed) {
		[pool release];
		return;
	}
	
	/// end capture setup ///

	ENTRY1(@" - starting capture thread for client: %@", client);
	
	isActive = YES;
	char capid[ [client cStringLength] ];	[client getCString:capid];
	// I may be cheating here (converting a char -> u_char)
	pcap_loop( captureHandle, 0, capture_callback, (u_char *)capid );
	pcap_close( captureHandle );
	isActive = NO;

	EXIT1(@" - ending capture thread for client: %@", client);
	[pool release];

	//???
	[NSThread exit];
}

- (void)stopCapture
{
	if (!isActive)
		return;
		
	ENTRY(@"stopCapture");
	pcap_breakloop( captureHandle );
	[queueProxy stopCollecting];
}

- (oneway void)killCapture
{
	if (!isActive)
		return;
		
	ENTRY(@"killCapture");
	pcap_breakloop( captureHandle );
}

#pragma mark -
#pragma mark Callback function

void packetHandler( u_char* user, const struct pcap_pkthdr* header, const u_char* packet )
{
	@try {
		[ [collectors objectForKey:[NSString stringWithCString:(char*)user]]
			addPacket:[NSData dataWithBytes:packet length:header->caplen]
			withHeader:[NSData dataWithBytes:header length:sizeof(struct pcap_pkthdr)]
		];
	}
	@catch (NSException *exception) {
		NSLog( @"exception in packetHandler: %@", [exception  reason] );
		[collectors removeObjectForKey:[NSString stringWithCString:(char*)user] ];
		//need to stop the capture somehow... not sure exactly how
	}
}

@end
