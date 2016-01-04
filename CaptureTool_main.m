//
//  CaptureTool-main.m
//  Eavesdrop
//
//  Created by Eric Baur on Tue Oct 5 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Capture.h"
#import "Authorization.h"

int main(int argc, const char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	Capture *captureObject;
	
	if (argc < 6) {
		printf( "not enough arguments:" );
		printf( "\tserverIdent clientIdent captureType live|dead device filter p|nop" );
		return -1;
	}

	NSString *serverIdent = [@(argv[1]) retain];
	NSString *clientIdent = [@(argv[2]) retain];
	NSString *captureType = [@(argv[3]) retain];
	NSString *device = [@(argv[4]) retain];
	NSString *filter = [@(argv[5]) retain];
	NSString *promiscuousString = [@(argv[6]) retain];
	
	BOOL promiscuous;
	if ( [promiscuousString isEqualToString:@"nop"] ) {
		promiscuous = NO;
	} else {
		promiscuous = YES;
	}
	
	INFO(NSLog( @"CaptureTool listening with identifier: %@, using queue: %@", serverIdent, clientIdent ));
	if ([captureType isEqualToString:@"live"]) {
 		INFO(NSLog( @"CaptureTool using device: %@ with filter: %@ [%@]", device, filter, promiscuousString ));
		captureObject = [[Capture alloc]
			initWithServerIdentifier:serverIdent
			clientIdentifier:clientIdent
			device:device
			filter:filter
			promiscuous:promiscuous
		];
	} else if ([captureType isEqualToString:@"dead"]) {
		INFO(NSLog( @"CaptureTool using file: %@ with filter: %@ [%@]", device, filter, promiscuousString ));
		captureObject = [[Capture alloc]
			initWithServerIdentifier:serverIdent
			clientIdentifier:clientIdent
			file:device
			filter:filter
			promiscuous:promiscuous
		];
	} else {
		captureObject = nil;
	}
	
	if (!captureObject) {
		NSLog( @"CaptureTool failed to initalize.  Exiting." );
		[captureObject release];
		[pool release];
		return -1;
	}
	
	if (![captureObject _startCapture]) {
		NSLog( @"CaptureTool failed to start capture." );
		[captureObject release];
		[pool release];
		return 1;
	}
	
	[NSTimer scheduledTimerWithTimeInterval:5
		target:captureObject
		selector:@selector(checkKeepAlive)
		userInfo:nil
		repeats:YES
	];

	[[NSRunLoop currentRunLoop] run];
	
	NSLog( @"CaptureTool will exit..." );
	
	[captureObject release];
	[pool release];
	
	NSLog( @"CaptureTool is done." );
	
	return 0;
}
