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
{	ENTRY;
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
{	ENTRY;
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
{	ENTRY;
    INFO( @"setClient:%@", newClient );
	[client release];
	client = [newClient retain];
}

- (NSString *)saveFile
{
	return saveFilename;
}

- (void)setSaveFile:(NSString *)saveFile
{	ENTRY;
    INFO( @"setSaveFile:%@", saveFile );
	[saveFilename release];
	saveFilename = [saveFile retain];
}

- (NSString *)readFile
{
	return readFilename;
}

- (void)setReadFile:(NSString *)readFile
{	ENTRY;
    INFO( @"setReadFile:%@", readFile  );
	[readFilename release];
	readFilename = [readFile retain];
}

- (NSString *)captureFilter
{
	return filter;
}

- (void)setCaptureFilter:(NSString *)filterString
{	ENTRY;
    INFO( @"setCaptureFilter:%@", filterString );
	[filter release];
	filter = [filterString retain];
}

- (NSString *)interface
{
	return interface;
}

- (void)setInterface:(NSString *)newInterface
{	ENTRY;
    INFO( @"setInterface:%@", newInterface );
	[interface release];
	interface = [newInterface retain];
}

- (BOOL)promiscuous
{
	return promiscuous;
}

- (void)setPromiscuous:(BOOL)promiscuousMode
{	ENTRY;
	promiscuous = promiscuousMode;
}

- (BOOL)capturesPayload
{
	return capturesPayload;
}

- (void)setCapturesPayload:(BOOL)shouldCapture
{	ENTRY;
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
	ENTRY;
	DEBUG( @"saving to file: %@", saveFilename );

	pcap_t *saveHandle = (pcap_t *)pcap_open_dead( DLT_EN10MB, 65535 );
	pcap_dumper_t *dumpHandle = pcap_dump_open( saveHandle, [saveFilename cStringUsingEncoding:NSASCIIStringEncoding] );
	
	id tempPacket;
	int count = 0;
	NSEnumerator *en = [packetsArray objectEnumerator];

	while ( tempPacket = [en nextObject] ) {
		struct pcap_pkthdr *tempHeader = (struct pcap_pkthdr *)[[tempPacket valueForKey:@"packetHeaderData"] bytes];

		NSData *tempPacketData = [tempPacket valueForKey:@"packetPayloadData"];
		u_char *tempPayload = (u_char *)[tempPacketData bytes];
		
		if ( tempHeader && tempPayload ) {
			pcap_dump( (u_char *)dumpHandle, tempHeader, tempPayload );
			count++;
		}
	}
	DEBUG( @"wrote %@ packets", [NSNumber numberWithInt:count] );
	
	pcap_close( saveHandle );
	EXIT;
}

- (void)startCapture
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSThread setThreadPriority:1.0];

	ENTRY;
	if (!client) {
		ERROR( @"can't start capture for null client!");
		[pool release];
		return;
	}
	
	DEBUG( @"vending objects" );
	[DOHelpers vendObject:self withName:[self description] local:YES];
	
	int tries = 0;
	while ( !queueProxy && tries<3 ) {
		queueProxy = [DOHelpers getProxyWithName:client protocol:@protocol(PacketQueue) host:nil];

		if (!queueProxy) {
			WARNING( @"failed to get queueProxy for client: %@", client );
			[pool release];
			return;
		}
		tries++;
		sleep(1);
	}
	DEBUG( @"set collector with queueProxy: %@", [queueProxy description] );
	[CaptureThread setCollector:queueProxy withName:client ];

	/// start capture setup ///
	
	DEBUG( @" - setting up capture" );
	
	BOOL setupFailed = NO;
	
	char filter_app[ [filter lengthOfBytesUsingEncoding:NSASCIIStringEncoding] ];
	char dev[ [interface lengthOfBytesUsingEncoding:NSASCIIStringEncoding] ];
	unsigned int captureSize;

	int size_ethernet   = sizeof( struct ether_header	);
	int size_ip			= sizeof( struct ip );
	int size_tcp		= sizeof( struct tcphdr );
	
	DEBUG( @"filter = %@ (%d bytes)", filter, [filter lengthOfBytesUsingEncoding:NSASCIIStringEncoding] );
	strncpy( filter_app, [filter cStringUsingEncoding:NSASCIIStringEncoding], [filter lengthOfBytesUsingEncoding:NSASCIIStringEncoding]+1 );
	DEBUG( @"cString filter = %s", filter_app );
	
	DEBUG( @"interface = %@ (%d bytes)", interface, [interface lengthOfBytesUsingEncoding:NSASCIIStringEncoding] );
	strncpy( dev, [interface cStringUsingEncoding:NSASCIIStringEncoding], [interface lengthOfBytesUsingEncoding:NSASCIIStringEncoding]+1 );
	DEBUG( @"cString interface = %s", dev );
	
	if (capturesPayload)
		captureSize = 65535;
	else
		captureSize = ( size_ethernet + size_ip + size_tcp );
	
	if (readFilename)
		captureHandle = pcap_open_offline( [readFilename cStringUsingEncoding:NSASCIIStringEncoding], errbuf );
	else
		captureHandle = pcap_open_live( dev, captureSize, promiscuous, 1, errbuf );
		
//	if (saveFilename)
//		saveHandle = pcap_dump //???
		
	if (!captureHandle) {
		ERROR( @"capture failed: %s", errbuf );
		ERROR( @"using device:%@ with filter:%@",interface,filter);
		setupFailed = YES;
	}

	pcap_lookupnet(dev, &netp, &maskp, errbuf);
	if( pcap_compile(captureHandle, &fp, filter_app, 0, netp) == -1) {
			ERROR( @"pcap_compile failed for filter:%s\n", filter_app );
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

	INFO(@" - starting capture thread for client: %@", client);
	
	isActive = YES;
	char capid[ [client lengthOfBytesUsingEncoding:NSASCIIStringEncoding] ];
	strncpy( capid, [client cStringUsingEncoding:NSASCIIStringEncoding], [client lengthOfBytesUsingEncoding:NSASCIIStringEncoding] );
	
	// I may be cheating here (converting a char -> u_char)
	pcap_loop( captureHandle, 0, capture_callback, (u_char *)capid );
	pcap_close( captureHandle );
	isActive = NO;

	INFO(@" - ending capture thread for client: %@", client);
	[pool release];

	//???
	[NSThread exit];
}

- (void)stopCapture
{
	if (!isActive)
		return;
		
	ENTRY;
	pcap_breakloop( captureHandle );
	[queueProxy stopCollecting];
}

- (oneway void)killCapture
{
	if (!isActive)
		return;
		
	ENTRY;
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
