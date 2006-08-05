//
//  TCPPacketDefaults.m
//  Eavesdrop
//
//  Created by Eric Baur on 7/11/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "TCPPacketDefaults.h"


@implementation TCPPacketDefaults

#pragma mark -
#pragma mark Setup methods

- (id)initWithSettings:(NSDictionary *)settingsDict
{
	ENTRY( @"initWithSettings:" );
	self = [super initWithSettings:settingsDict];
	if (self) {
		//nothing yet
		if ( ![NSBundle loadNibNamed:@"TCPPacketDefaults" owner:self] ) {
			ERROR( @"failed to load TCPPacketsDefaults nib" );
		}
	}
	return self;
}

#pragma mark -
#pragma mark Accessor methods

- (NSMutableArray *)flagsArray
{
	if ( !flagsArray ) {
		flagsArray = [[NSMutableArray arrayWithContentsOfFile:
			[[NSBundle bundleForClass:[self class]] pathForResource:@"TCPFlags" ofType:@"plist"]
		] retain];
	}
	return flagsArray;
}

- (NSMutableDictionary *)flagsDictionary
{
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
	
	NSEnumerator *en = [[self flagsArray] objectEnumerator];
	NSDictionary *flagDict;
	while ( flagDict=[en nextObject] ) {
		[tempDict setObject:flagDict forKey:[flagDict objectForKey:@"shortName"] ];
	}
	return tempDict;
}

#pragma mark -
#pragma mark Overridden methods

- (void)getDefaultsFromDictionary:(NSDictionary *)defaultsDict
{
	[super getDefaultsFromDictionary:defaultsDict];
}

- (NSDictionary *)defaultsDict
{
	NSMutableDictionary *defaultsDict = [[super defaultsDict] mutableCopy];
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
	if ( flagsArray ) {
		NSEnumerator *en = [flagsArray objectEnumerator];
		NSDictionary *flagDict;
		while ( flagDict=[en nextObject] ) {
			[tempDict
				setObject:[NSArchiver archivedDataWithRootObject:[flagDict objectForKey:@"color"]]
				forKey:[NSString stringWithFormat:@"%@color",[flagDict objectForKey:@"shortName"]]
			];
		}
	}
	[defaultsDict setObject:tempDict forKey:@"flags"];
	return [defaultsDict copy];
}

@end
