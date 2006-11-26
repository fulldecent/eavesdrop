//
//  CaptureServer_main.m
//  Eavesdrop
//
//  Created by Eric Baur on 5/16/06.
//  Copyright Eric Shore Baur 2006 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <BHLogger/BHLogging.h>
#import "CaptureServer.h"

int main(int argc, char *argv[])
{
	NSString *self = @"CaptureServer_main";	//hack for debug macros
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CaptureServer *captureServer;
	NSString *serverIdentifier = @"CaptureServer";
	NSString *startingClient = nil;
	
	//change the identifier if it is passed on the command line
	if (argc > 1) {
		serverIdentifier = [NSString stringWithCString:argv[1]];
	} else if ( argc > 2 ) {
		startingClient = [NSString stringWithCString:argv[2]];
	}

	DEBUG1( @"CaptureServer listening with identifier: %@", serverIdentifier );
	captureServer = [[CaptureServer alloc] initWithIdentifier:serverIdentifier client:startingClient];
	
	[[NSRunLoop currentRunLoop] run];
	
	DEBUG( @"CaptureTool will exit..." );	
	[captureServer release];
	[pool release];
	
	DEBUG( @"CaptureTool is done." );
	return 0;
}
