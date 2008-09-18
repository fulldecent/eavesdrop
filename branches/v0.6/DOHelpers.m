//
//  DOHelpers.m
//  Eavesdrop
//
//  Created by Eric Baur on 5/21/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "DOHelpers.h"


@implementation DOHelpers

static NSMutableDictionary *connectionsDict;

+ (void)initialize
{
	connectionsDict = [[NSMutableDictionary alloc] init];
}

+ (BOOL)vendObject:(id)object withName:(NSString *)name local:(BOOL)local
{
	NSConnection *connection;
	if (local) {
		connection = [[[NSConnection alloc] initWithReceivePort:[NSPort port] sendPort:nil] autorelease];
	} else {
		NSSocketPort *port = [[[NSSocketPort alloc] init] autorelease];
		connection = [NSConnection connectionWithReceivePort:port sendPort:nil];
		[[NSSocketPortNameServer sharedInstance] registerPort:port name:name];
		[connection setRootObject:self];
	}
	[connectionsDict setObject:connection forKey:name];
	[connection setRootObject:object];

	if (![connection registerName:name]) {
		WARNING( @"registered name '%@' taken.", name );
		return NO;
	} else {
		DEBUG( @"vended object with name: %@", name );
	}
	return YES;
}

+ (id)getProxyWithName:(NSString *)name protocol:(Protocol *)protocol host:(NSString *)remoteHost
{
	id proxy;
	NSConnection *connection;
	
	if (remoteHost==nil) {
		DEBUG( @"checking for local proxy" );
		connection = [NSConnection connectionWithRegisteredName:name host:nil];
	} else {
		DEBUG( @"checking for remote proxy" );
		NSPort *port = [[NSSocketPortNameServer sharedInstance] portForName:name host:@"*"];
		connection = [NSConnection connectionWithReceivePort:nil sendPort:port];	
	}

	proxy = [connection rootProxy];
	[proxy setProtocolForProxy:protocol];
	
	return proxy;
}

@end
