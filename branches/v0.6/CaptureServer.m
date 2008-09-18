//
//  CaptureServer.m
//  Eavesdrop
//
//  Created by Eric Baur on 5/17/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "CaptureServer.h"


@implementation CaptureServer

#pragma mark -
#pragma mark Setup Methods

- (id)init
{
	return [self initWithIdentifier:@"CatpureServer"];
}

- (id)initWithIdentifier:(NSString *)serverIdentifier
{
	return [self initWithIdentifier:serverIdentifier client:nil];
}

- (id)initWithIdentifier:(NSString *)serverIdentifier client:(NSString *)firstClient
{
	DEBUG( [NSString stringWithFormat:@"[CaptureServer initWithidentifier:%@ client:%@]", serverIdentifier, firstClient] );
	self = [super init];
	if (self) {
		[self setIdentifier:serverIdentifier];
		if (!firstClient) {
			firstClient = @"localhost";
		}
		[self setAllowedHosts:[NSArray arrayWithObject:firstClient] ];
		[self setParentHost:firstClient];
		[self setPollingInterval:10];
		
		captureThreads = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}

#pragma mark -
#pragma mark Accessor Methods

- (NSString *)identifier
{
	return identifier;
}

- (oneway void)setIdentifier:(NSString *)newIdentifier
{
	ENTRY;
    INFO( @"[CaptureServer setIdentifier:%@]", newIdentifier );
	//for now, we'll ignore requests to change the identifier
	if (identifier)
		return;
	identifier = [newIdentifier retain];

	if ( [DOHelpers vendObject:self withName:identifier local:YES] ) {
		DEBUG( @"succeeded in vending object (%@)", identifier );
	} else {
		DEBUG( @"failed to vend object (%@)", identifier );
	}
	EXIT( @"setIdentifier:" );
}

- (NSArray *)allowedHosts
{
	return allowedHosts;
}

- (oneway void)setAllowedHosts:(NSArray *)hostArray
{
	[allowedHosts release];
	allowedHosts = [hostArray retain];
}

- (int)pollingInterval
{
	return pollingInterval;
}

- (oneway void)setPollingInterval:(int)newInterval
{
	pollingInterval = newInterval;
	
	[pollingTimer invalidate];
	[pollingTimer release];
	pollingTimer = nil;

	if ( pollingInterval==0 ) {
		DEBUG( @"no polling interval, server will never die" );
	} else {
		pollingTimer = [[NSTimer
			scheduledTimerWithTimeInterval:pollingInterval
			target:self
			selector:@selector(pingApplication)
			userInfo:nil
			repeats:YES
		] retain];	
	}
}

- (BOOL)hidesServerMessages
{
	return hidesServerMessages;
}

- (oneway void)setHidesServerMessages:(BOOL)hideMessagesState
{
	hidesServerMessages = hideMessagesState;
	//need to modify the filter to allow for this
}

- (NSArray *)interfaces
{	ENTRY;
	//it would be nice to really detect things here!!!
	return [NSArray arrayWithObjects:@"en0", @"en1", @"en2", nil];
}


#pragma mark -
#pragma mark Capture Properties

- (NSString *)parentHost
{
	return parentHost;
}

- (oneway void)setParentHost:(NSString *)newParent
{	//should change this to work with URLs
	if ( allowedHosts==nil || [allowedHosts containsObject:newParent] ) {
		[parentHost release];
		parentHost = newParent;

		ENTRY;
		INFO( @"[CaptureServer setParentHost:%@]", newParent );

		clientAppDelegateProxy = [[DOHelpers
			getProxyWithName:@"EavesdropAppDelegate"
			protocol:@protocol(ClientAppDelegate)
			host:nil
		] retain];
		DEBUG( @" - got clientAppDelegateProxy: %@", [clientAppDelegateProxy description] );
	}
}

- (NSArray *)clients
{
	return  [captureThreads allKeys];
}

- (NSArray *)captures
{
	return [captureThreads allValues];
}

- (oneway void)addCaptureForClient:(NSString *)newClient
{
	CaptureThread *newCapture = [[[CaptureThread alloc] init] autorelease];
	[newCapture setClient:newClient];
	[captureThreads setObject:newCapture forKey:newClient];
}

- (oneway void)removeCaptureForClient:(NSString *)oldClient
{
	//I should probably stop the capture first
	[captureThreads removeObjectForKey:oldClient];
}

- (NSString *)saveFileForClient:(NSString *)clientIdentifier
{
	return [[captureThreads objectForKey:clientIdentifier] saveFile];
}

- (oneway void)setSaveFile:(NSString *)saveFile forClient:(NSString *)clientIdentifier
{
	[[captureThreads objectForKey:clientIdentifier] setSaveFile:saveFile];
}

- (NSString *)readFileForClient:(NSString *)clientIdentifier
{
	return [[captureThreads objectForKey:clientIdentifier] readFile];
}

- (oneway void)setReadFile:(NSString *)readFile forClient:(NSString *)clientIdentifier
{
	[[captureThreads objectForKey:clientIdentifier] setReadFile:readFile];
}

- (NSString *)captureFilterForClient:(NSString *)clientIdentifier
{
	return [[captureThreads objectForKey:clientIdentifier] captureFilter];
}

- (oneway void)setCaptureFilter:(NSString *)filterString forClient:(NSString *)clientIdentifier
{
	[[captureThreads objectForKey:clientIdentifier] setCaptureFilter:filterString];
}

- (NSString *)interfaceForClient:(NSString *)clientIdentifier
{
	return [[captureThreads objectForKey:clientIdentifier] interface];
}

- (oneway void)setInterface:(NSString *)newInterface forClient:(NSString *)clientIdentifier
{
	[[captureThreads objectForKey:clientIdentifier] setInterface:newInterface];
}

- (BOOL)promiscuousForClient:(NSString *)clientIdentifier
{
	return [[captureThreads objectForKey:clientIdentifier] promiscuous];
}

- (void)setPromiscuous:(BOOL)promiscuousMode forClient:(NSString *)clientIdentifier
{
	[[captureThreads objectForKey:clientIdentifier] setPromiscuous:promiscuousMode];
}

- (BOOL)capturesPayloadForClient:(NSString *)clientIdentifier
{
	return [[captureThreads objectForKey:clientIdentifier] capturesPayload];
}

- (oneway void)setCapturesPayload:(BOOL)shouldCapture forClient:(NSString *)clientIdentifier
{
	[[captureThreads objectForKey:clientIdentifier] setCapturesPayload:shouldCapture];
}

- (BOOL)isActiveForClient:(NSString *)clientIdentifier
{
	//return if the capture is currently running or not
	return [[captureThreads objectForKey:clientIdentifier] isActive];
}

#pragma mark -
#pragma mark Actions

- (void)pingApplication
{
	//DEBUG( @"pingApplication" );
	if (!pollingInterval)
		return;
		
	@try {
		if ([clientAppDelegateProxy isAppRunning])
			return;
	}
	@catch (NSException *e) {
		ERROR( @"caught exception trying to ping application: %@", [e reason] );
		[self killServer];
	}
	//[self killServer];	//probably won't ever get here
}

- (oneway void)startCaptureForClient:(NSString *)clientIdentifier
{
	ENTRY;
	INFO( @"startCaptureForClient:%@", clientIdentifier );

	CaptureThread *captureThread = [captureThreads objectForKey:clientIdentifier];
	
	[NSThread detachNewThreadSelector:@selector(startCapture) toTarget:captureThread withObject:nil];

	[clientAppDelegateProxy captureTaskStarted];
}

- (BOOL)startCaptureWithFilter:(NSString *)captureFilter
	promiscuous:(BOOL)capturePromiscuous
	onInterface:(NSString *)captureInterface
	forClient:(NSString *)clientIdentifier
{
	[self addCaptureForClient:clientIdentifier];
	[self setCaptureFilter:captureFilter forClient:clientIdentifier];
	[self setPromiscuous:capturePromiscuous forClient:clientIdentifier];
	[self setInterface:captureInterface forClient:clientIdentifier];

	[[captureThreads objectForKey:clientIdentifier] startCapture];
	
	return YES;
}

- (oneway void)stopCaptureForClient:(NSString *)clientIdentifier
{
	[[captureThreads objectForKey:clientIdentifier] stopCapture];
}

- (oneway void)killServer
{
	ENTRY;
	
	[pollingTimer invalidate];
	
	NSEnumerator *en = [[captureThreads allValues] objectEnumerator];
	CaptureThread *captureThread;
	while ( captureThread = [en nextObject] ) {
		[captureThread killCapture];
	}
	//this may be bad... it may be proper...  ???
	//[[NSConnection defaultConnection] invalidate];
	[[NSApplication sharedApplication] terminate:self];
}

@end
