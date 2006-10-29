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

- (NSString *)settingsNibName
{
	return @"TCPPacketDefaults";
}

#pragma mark -
#pragma mark Accessor methods

- (NSMutableArray *)flagsArray
{
	if ( !flagsArray ) {
		flagsArray = [[NSMutableArray arrayWithContentsOfFile:
			[[NSBundle bundleForClass:[self class]] pathForResource:@"TCPFlags" ofType:@"plist"]
		] retain];
		currentFlagSelection = [flagsArray objectAtIndex:0];
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
	ENTRY( @"getDefaultsFromDictionary" );
	[super getDefaultsFromDictionary:defaultsDict];

	NSDictionary *defaultsColors = [defaultsDict valueForKey:@"flagColors"];
	NSEnumerator *en = [[self flagsArray] objectEnumerator];
	NSMutableDictionary *tempDict;
	while ( tempDict=[en nextObject] ) {
		id colorData = [defaultsColors objectForKey:[tempDict objectForKey:@"shortName"]];
		NSColor *tempColor = nil;
		if (colorData)
			tempColor = [NSUnarchiver unarchiveObjectWithData:colorData];
		if (tempColor)
			[tempDict setObject:tempColor forKey:@"color"];
	}
	INFO( [flagsArray description] );
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
				forKey:[flagDict objectForKey:@"shortName"]
			];
		}
	}
	[defaultsDict setObject:tempDict forKey:@"flagColors"];
	return [defaultsDict copy];
}

@end
