//
//  TCPServerPortAggregateDefaults.m
//  Eavesdrop
//
//  Created by Eric Baur on 10/15/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "TCPServerPortAggregateDefaults.h"

@implementation TCPServerPortAggregateDefaults

#pragma mark -
#pragma mark Setup methods

- (NSString *)settingsNibName
{
	return @"TCPServerPortAggregateDefaults";
}

#pragma mark -
#pragma mark Accessor methods

- (NSMutableArray *)portsArray
{
	ENTRY;
	if ( !portsArray ) {
		portsArray = [[NSMutableArray arrayWithContentsOfFile:
			[[NSBundle bundleForClass:[self class]] pathForResource:@"TCP_UDP_Ports" ofType:@"plist"]
		] retain];
		int i;
		int count = [portsArray count];
		for ( i=count-1; i>=0; i-- ) {
			if ( [[[portsArray objectAtIndex:i] objectForKey:@"TCP"] boolValue] == NO ) {
				[portsArray removeObjectAtIndex:i];
			}
		}
	}
	return portsArray;
}

#pragma mark -
#pragma mark Overridden methods

- (void)getDefaultsFromDictionary:(NSDictionary *)defaultsDict
{
	[super getDefaultsFromDictionary:defaultsDict];
	
	[self willChangeValueForKey:@"defaultsPortsArray"];
	NSArray *defaultsPortsArray = [[defaultsDict objectForKey:@"ports"] retain];
	if (defaultsPortsArray) {
		DEBUG( @"using portsArray from defaults" );
		[portsArray removeAllObjects];
		[portsArray addObjectsFromArray:defaultsPortsArray];
	} else {
		DEBUG( @"using factory portsArray" );
	}
	[self didChangeValueForKey:@"defaultsPortsArray"];
	
	[self willChangeValueForKey:@"useLowPort"];
	id tempObject = [defaultsDict objectForKey:@"useLowPort"];
	if ( tempObject ) {
		DEBUG( @"using useLowPort from defaults" );
		useLowPort = [tempObject boolValue];
	} else {
		DEBUG( @"using factory setting for useLowPort" );
		useLowPort = YES;
	}
	[self didChangeValueForKey:@"useLowPort"];	
}

- (NSDictionary *)defaultsDict
{
	NSMutableDictionary *defaultsDict = [[super defaultsDict] mutableCopy];

	if (portsArray) {
		DEBUG( @"save user's ports array" );
		[defaultsDict setObject:portsArray forKey:@"ports"];
	}
	
	[defaultsDict setObject:[NSNumber numberWithBool:useLowPort] forKey:@"useLowPort"];

	return [defaultsDict copy];
}

@end
