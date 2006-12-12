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

- (NSDictionary *)flagGroupsDictionary
{
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
	
	NSEnumerator *en = [flagGroupsArray objectEnumerator];
	NSDictionary *flagDict;
	while ( flagDict=[en nextObject] ) {
		[tempDict setObject:[flagDict objectForKey:@"groupColor"] forKey:[flagDict objectForKey:@"groupString"] ];
	}
	return [tempDict copy];
}

#pragma mark -
#pragma mark Actions

- (IBAction)changeFlags:(id)sender
{
	ENTRY( @"changeFlags:" );
	
	int i;
	int count = [sender segmentCount];
	NSMutableString *tempString = [NSMutableString string];
	for (i=0; i<count; i++) {
		if ( [sender isSelectedForSegment:i] ) {
			[tempString appendString:[sender labelForSegment:i] ];
		} else {
			[tempString appendString:@"-"];
		}
	}
	DEBUG1( @"flags: %@", tempString );
	
	[[flagGroupsArrayController valueForKey:@"selection"] setValue:tempString forKey:@"groupString" ];
}


#pragma mark -
#pragma mark Overridden methods

- (void)getDefaultsFromDictionary:(NSDictionary *)defaultsDict
{
	//is it okay to "init" from this method?

	ENTRY( @"getDefaultsFromDictionary" );
	[super getDefaultsFromDictionary:defaultsDict];
	
	[self willChangeValueForKey:@"flagsOverlayGroup"];
	flagsOverlayGroup = [[defaultsDict valueForKey:@"flagsOverlayGroup"] boolValue];
	[self didChangeValueForKey:@"flagsOverlayGroup"];

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
	
	[self willChangeValueForKey:@"flagGroupsArray"];
	[flagGroupsArray release];
	flagGroupsArray = [[NSMutableArray alloc] init];
	NSDictionary *flagGroupColors = [defaultsDict valueForKey:@"flagGroupColors"];
	en = [flagGroupColors keyEnumerator];
	NSString *tempString;
	while ( tempString=[en nextObject] ) {
		NSColor *tempColor = [NSUnarchiver unarchiveObjectWithData:
			[flagGroupColors valueForKey:tempString]
		];
		if ( tempColor ) {
			[flagGroupsArray addObject:
				[NSMutableDictionary dictionaryWithObjectsAndKeys:
					tempString,		@"groupString",
					tempColor,		@"groupColor",
					nil
				]
			];
		}
	}
	[self didChangeValueForKey:@"flagGroupsArray"];
	INFO( [flagGroupsArray description] );
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
	[defaultsDict setObject:[tempDict copy] forKey:@"flagColors"];
	
	NSEnumerator *en = [flagGroupsArray objectEnumerator];
	tempDict = [NSMutableDictionary dictionary];
	NSDictionary *flagDict;
	while ( flagDict=[en nextObject] ) {
		[tempDict
			setObject:[NSArchiver archivedDataWithRootObject:[flagDict objectForKey:@"groupColor"]]
			forKey:[flagDict objectForKey:@"groupString"]
		];
	}
	[defaultsDict setObject:[tempDict copy] forKey:@"flagGroupColors"];
	
	[defaultsDict setObject:[NSNumber numberWithBool:flagsOverlayGroup] forKey:@"flagsOverlayGroup"];
	
	return [defaultsDict copy];
}

@end
