//
//  CaptureServer.h
//  Eavesdrop
//
//  Created by Eric Baur on 5/17/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <BHDebug/BHDebug.h>

#import "DOHelpers.h"
#import "CaptureHandlers.h"
#import "EavesdropAppDelegate.h"

#import "CaptureThread.h"

@interface CaptureServer : NSObject <CaptureServer>
{
	NSString *identifier;
	NSArray *allowedHosts;
	NSMutableDictionary *captureThreads;

	NSString *parentHost;
	
	NSTimer *pollingTimer;
	int pollingInterval;
	
	BOOL hidesServerMessages;
	
	id clientAppDelegateProxy;
}

- (id)initWithIdentifier:(NSString *)serverIdentifier;
- (id)initWithIdentifier:(NSString *)serverIdentifier client:(NSString *)firstClient;

//see CaptureHandlers.h for other method definitions

- (void)pingApplication;

@end
