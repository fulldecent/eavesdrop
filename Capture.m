//
//  Capture.m
//  Capture
//
//  Created by Eric Baur on Tue Jun 29 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

#import "Capture.h"
#import "Authorization.h"

@implementation Capture

static NSMutableDictionary *controllers;

+ (void)initialize
{
	[Capture sharedControllersDictionary];
}

+ (id)sharedControllersDictionary
{
	if (!controllers)
		controllers = [[NSMutableDictionary dictionary] retain];
	return controllers;
}

+ (BOOL)setController:(id)controller withName:(NSString *)name
{
	if (!controllers)
		controllers = [Capture sharedControllersDictionary];
		
	if (controllers[name]) {
		return NO;
	} else {
		controllers[name] = controller;
		return YES;
	}
}

+ (void)removeControllerWithName:(NSString *)name
{
	if (!controllers)
		controllers = [Capture sharedControllersDictionary];
	
	[controllers removeObjectForKey:name ];
}

+ (id)controllerWithName:(NSString *)name
{
	if (!controllers)
		controllers = [Capture sharedControllersDictionary];
	return controllers[name];
}

+ (NSArray *)interfaces
{
/*
	// need to figure out a way to enumerate the interfaces
	// might want to look up pcap version and use the new function if it's present...
	char error[PCAP_ERRBUF_SIZE]; 
	char *defaultDev = pcap_lookupdev( error );
	//need to recover if no interfaces!!!
	return [NSArray arrayWithObject:[NSString stringWithCString:defaultDev] ];
*/
	return @[@"en0", @"en1", @"en2"];
}

- (instancetype)initWithServerIdentifier:(NSString *)serverIdent clientIdentifier:(NSString *)clientIdent
{
	self = [super init];
	queueIdentifier = [clientIdent retain];
	toolIdentifier = [serverIdent retain];
	promiscuous = YES;
	return self;
}

- (instancetype)initWithServerIdentifier:(NSString *)serverIdent clientIdentifier:(NSString *)clientIdent
						device:(NSString *)usingDevice filter:(NSString *)usingFilter
						promiscuous:(BOOL)usingPromiscuous
{
	self = [super init];
	queueIdentifier = [clientIdent retain];

	if (serverIdent) {
		NSConnection *serverConnection = [NSConnection defaultConnection];
		serverConnection.rootObject = self;

		if ([serverConnection registerName:serverIdent] == NO) {
			NSLog( @"DistributedObject - registered name %@ taken.", serverIdent );
			return nil;
		}
	}
	
	capturePayload = YES; //???
	promiscuous = usingPromiscuous;
	
	[self setDevice:usingDevice];
	[self setCaptureFilter:usingFilter];

	my_callback = &packetHandler;
/*
	[NSTimer scheduledTimerWithTimeInterval:5
		target:self
		selector:@selector(checkKeepAlive)
		userInfo:nil
		repeats:YES
	];
*/	
	return self;
}

- (instancetype)initWithServerIdentifier:(NSString *)serverIdent clientIdentifier:(NSString *)clientIdent
						file:(NSString *)usingFile filter:(NSString *)usingFilter
						promiscuous:(BOOL)usingPromiscuous
{
	self = [super init];
	queueIdentifier = [clientIdent retain];

	if (serverIdent) {
		NSConnection *serverConnection = [NSConnection defaultConnection];
		serverConnection.rootObject = self;

		if ([serverConnection registerName:serverIdent] == NO) {
			NSLog( @"DistributedObject - registered name %@ taken.", serverIdent );
			return nil;
		}
	}
	
	capturePayload = YES; //???
	promiscuous = usingPromiscuous;
	
	[self setReadFile:usingFile];
	[self setCaptureFilter:usingFilter];

	my_callback = &packetHandler;
	
	return self;
}

- (void)setSaveFile:(NSString *)saveFile
{
	[outfile release];
	outfile = saveFile;
	[outfile retain];
}

- (void)setReadFile:(NSString *)readFile
{
	[infile release];
	infile = readFile;
	[infile retain];
	
	[captureID release];
	captureID = [NSString stringWithFormat:@"%@:%@",infile,filter];
	[captureID retain];
}

- (void)setCapturesPayload:(BOOL)shouldCapture
{
	capturePayload = shouldCapture;
}


- (BOOL)capturesPayload
{
	return capturePayload;
}

- (BOOL)startCapture
{
	ENTRY(NSLog(@"[Capture startCapture]"));
	toolIdentifier = [[NSString stringWithFormat:@"captureTool-%d", captureID] retain];
	INFO(NSLog(@"launch captureTool with ident: %@",toolIdentifier));

	NSString *typeArg;
	NSString *deviceArg;
	if (infile) {
		typeArg = @"dead";
		deviceArg = infile;
	} else {
		typeArg = @"live";
		deviceArg = device;
	}
	
	if (infile) {
		[NSTask
			launchedTaskWithLaunchPath:[[NSBundle mainBundle] pathForAuxiliaryExecutable:@"CaptureTool"]
			arguments:@[toolIdentifier,
				queueIdentifier,
				typeArg,
				deviceArg,
				filter,
				@""]
		];
		return active=YES;
	} else {
		// need to bulid the arguments into C-Strings
		char toolString[ [toolIdentifier cStringLength] ];		[toolIdentifier getCString:toolString];
		char queueString[ [queueIdentifier cStringLength] ];	[queueIdentifier getCString:queueString];
		char typeString[ [typeArg cStringLength] ];				[typeArg getCString:typeString];
		char deviceString[ [deviceArg cStringLength] ];			[deviceArg getCString:deviceString];
		char filterString[ [filter cStringLength] ];			[filter getCString:filterString];
		char promiscuousString[ 4 ] = "nop";
		if ( promiscuous ) {
			promiscuousString[0]='p';	promiscuousString[1]='\0';
		} //else {
		//	promiscuousString[0]='p';	promiscuousString[1]='\0';
		//}
		
		char *arguments[] = {
			toolString,
			queueString,
			typeString,
			deviceString,
			filterString,
			promiscuousString,
			NULL
		};
		// need to launch with root permissions
		if ( authorize([[NSBundle mainBundle] pathForAuxiliaryExecutable:@"CaptureTool"].UTF8String,arguments) ) {
			INFO(NSLog(@"captureTask is NOT running"));
			return active=NO;	
		} else {
			INFO(NSLog(@"captureTask is running"));
			return active=YES;
		}
	}
}

- (BOOL)_startCapture
{
	ENTRY(NSLog(@"[Capture _startCapture]"));
	
	char filter_app[ [filter cStringLength] ];
	char dev[ [device cStringLength] ];
	unsigned int captureSize;

	int size_ethernet   = sizeof( struct sniff_ethernet );
	int size_ip			= sizeof( struct sniff_ip );
	int size_tcp		= sizeof( struct sniff_tcp );
	
	[filter getCString:filter_app];
	[device getCString:dev];
	
	if (capturePayload)
		captureSize = 65535;
	else
		captureSize = ( size_ethernet + size_ip + size_tcp );
	
	if (infile)
		captureHandle = pcap_open_offline( [infile cString], errbuf );
	else
		captureHandle = pcap_open_live( dev, captureSize, promiscuous, 1, errbuf );
		
//	if (outfile)
//		saveHandle = pcap_dump //???
		
	if (!captureHandle) {
		NSLog( @"capture failed: %s", errbuf );
		INFO(NSLog(@"using device:%@ with filter:%@",device,filter));
		return NO;
	}

	pcap_lookupnet(dev, &netp, &maskp, errbuf);
	if( pcap_compile(captureHandle, &fp, filter_app, 0, netp) == -1) {
			NSLog( @"pcap_compile failed for filter:%s\n", filter_app );
			return NO;
	}
	if (pcap_setfilter(captureHandle, &fp) == -1) {
			NSLog( @"pcap_setfilter failed.\n" );
			return NO;
	}

	[NSThread detachNewThreadSelector:@selector(captureThreadWithID:) toTarget:self withObject:captureID];
	
	return active=YES;
}

- (void)stopCapture
{
	if (!active)
		return;
		
	ENTRY(NSLog(@"[Capture stopCapture]"));

	id captureProxy = [NSConnection
		rootProxyForConnectionWithRegisteredName:toolIdentifier host:nil
	];
	[captureProxy setProtocolForProxy:@protocol(CaptureHandler)];
	INFO(NSLog(@"using proxy: %@",[captureProxy description]);)

	[captureProxy _stopCapture];
	active = NO;
}

- (void)_stopCapture
{
	ENTRY(NSLog(@"[Capture _stopCapture]");)
	pcap_breakloop( captureHandle );
	//this next line causes an error (???)
	//[[controllers objectForKey:captureID] stopCapture];
	[Capture removeControllerWithName:captureID];

	// does this belong here???
	[[NSApplication sharedApplication] stop:self];

	[NSThread exit];
}

- (void)captureThreadWithID:(NSString *)capID
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSThread setThreadPriority:1.0];
	NSConnection *serverConnection = [NSConnection defaultConnection];
	serverConnection.rootObject = self;

	INFO(NSLog(@"getting queueProxy with ident:%@ capID:%@",queueIdentifier,capID));
	queueProxy = [[NSConnection
			rootProxyForConnectionWithRegisteredName:queueIdentifier host:nil
		] retain
	];
	[queueProxy setProtocolForProxy:@protocol(PacketHandler)];
	INFO(NSLog(@"got queueProxy: %@",[queueProxy description]));

	[Capture setController:queueProxy withName:capID];
	ENTRY(NSLog(@"starting capture thread..."));
	char capid[ [capID cStringLength] ];	[capID getCString:capid];
	pcap_loop( captureHandle, 0, my_callback, capid );
	pcap_close( captureHandle );
	
	[queueProxy stopCapture];
	ENTRY(NSLog(@"...ending capture thread"));
	[pool release];
}

- (BOOL)isActive
{
	return active;
}
/*	THIS APPEARS TO BE BROKEN (THEIR FAULT)
- (NSDictionary *)stats
{
	struct pcap_stat *stats;
	
	pcap_stats( captureHandle, stats );
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:stats->ps_recv], @"received",
		[NSNumber numberWithInt:stats->ps_drop], @"dropped",
		[NSNumber numberWithInt:stats->ps_ifdrop], @"interface dropped",
		nil
	];
}
*/

- (void)setCaptureFilter:(NSString *)filterString
{
	ENTRY(NSLog(@"[Capture setCaptureFilter: %@]",filterString));
	[filter release];
	[captureID release];
	filter = [filterString retain];
	if (device)
		captureID = [[NSString stringWithFormat:@"%@:%@",device,filter] retain];
	else
		captureID = [[NSString stringWithFormat:@"%@:%@",infile,filter] retain];
}

- (void)setDevice:(NSString *)newDevice
{
	ENTRY(NSLog(@"[Capture setDevice: %@]",newDevice));
	[device release];
	[captureID release];
	device = [newDevice retain];
	captureID = [[NSString stringWithFormat:@"%@:%@",device,filter] retain];
}

- (void)setPromiscuous:(BOOL)promiscuousMode
{
	promiscuous = promiscuousMode;
}

- (void)setKeepAlive
{
	//NSLog( @"setKeepAlive" );
	keepAlive = YES;
}

- (void)unsetKeepAlive
{
	//NSLog( @"unsetKeepAlive" );
	keepAlive = NO;
}

- (void)checkKeepAlive
{
	//NSLog( @"checking keep alive" );
	if (!keepAlive) {
		[[NSApplication sharedApplication] stop:self];
	}
	keepAlive = NO;
}

void packetHandler( u_char* user, const struct pcap_pkthdr* header, const u_char* packet )
{
	[ controllers[[NSString stringWithCString:user]]
		addPacket:[NSData dataWithBytes:packet length:header->caplen]
		withHeader:[NSData dataWithBytes:header length:sizeof(struct pcap_pkthdr)]
	];
}

@end
