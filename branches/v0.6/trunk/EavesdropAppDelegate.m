//
//  EavesdropAppDelegate.m
//  Eavesdrop
//
//  Created by Eric Baur on 5/16/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "EavesdropAppDelegate.h"


@implementation EavesdropAppDelegate

+ (void)initialize
{
	//set initial values for defaults controloler;
	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
	
	[defaults setInitialValues:[NSDictionary dictionaryWithObjectsAndKeys:
			@"en0",							@"interface",
			[NSNumber numberWithBool:NO],	@"autoLaunchServer",
			[NSNumber numberWithBool:YES],	@"promiscuous",
			[NSNumber numberWithBool:YES],	@"readFileOnOpen",
			[NSNumber numberWithInt:100],	@"tableRefresh",
			nil
		]
	];
}

- (id)init
{
	ENTRY( @"init" );
	self = [super init];
	if (self) {
		if ( [DOHelpers vendObject:self withName:@"EavesdropAppDelegate" local:YES	] ) {
			DEBUG( @"succeeded in vending object (EavesdropAppDelegate)" );
		} else {
			DEBUG( @"failed to vend object (EavesdropAppDelegate)" );
		}
		
		//check to see if we should launch the server
		NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
		if ( [[[defaults values] valueForKey:@"autoLaunchServer"] boolValue] ) {
			[self launchCaptureServer:self];
		}
	}
	EXIT( [self description] );
	return self;
}

//- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
- (void)applicationWillFinishLaunching:(NSNotification*)notification
{	
	//ENTRY( @"applicationWillFinishLaunching:" );
	[pluginsController findAllPlugins];
}

- (void)captureTaskStarted
{
	//this is sent by the server
	DEBUG( @"captureTaskStarted" );
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{	
	ENTRY( @"applicationWillTerminate:" );

	[[DOHelpers getProxyWithName:@"CaptureServer" protocol:@protocol(CaptureServer) host:nil] killServer];
}

- (IBAction)launchCaptureServer:(id)sender
{
	ENTRY( @"launchCaptureServer:" );
	//I have no idea why the next two lines are needed...
	//... but w/out them the app never authorizes! ???
	NSConnection *throwAway;
	throwAway = [NSConnection defaultConnection];

	char *arguments[] = {};
	if ( authorize([[[NSBundle mainBundle] pathForAuxiliaryExecutable:@"CaptureServer"] UTF8String],arguments) ) {
		WARNING(@"captureTask is NOT running");
	} else {
		DEBUG(@"captureTask is running");
	}
}

///might not use this one...
- (IBAction)savePreferences:(id)sender
{
	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
	[defaults save:self];
	
	[pluginsController savePluginPreferences:self];
	
	[preferencesWindow close];
}

- (IBAction)cancelPreferences:(id)sender
{
	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
	[defaults revert:self];
	
	[preferencesWindow close];
}

- (BOOL)isAppRunning
{
	return YES;
}

@end
