//
//  PluginsController.m
//  Eavesdrop
//
//  Created by Eric Baur on 6/6/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "PluginsController.h"


@implementation PluginsController

- (id)init
{
	self = [super init];
	if (self) {
		dissectorDefaultsArray = [[NSMutableArray alloc] init];
		aggregateDefaultsArray = [[NSMutableArray alloc] init];
		decoderDefaultsArray = [[NSMutableArray alloc] init];
		pluginDefaultsArray = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)findAllPlugins
{
	ENTRY( @"findAllPlugins" );
	
	[self willChangeValueForKey:@"dissectorDefaultsArray"];
	[self willChangeValueForKey:@"aggregateDefaultsArray"];
	[self willChangeValueForKey:@"pluginDefaultsArray"];
	
	//load the default plugins
	[self activatePlugin:[[NSBundle bundleForClass:[Plugin class]] bundlePath] ];

	//load any found plugins
	NSString* folderPath = [[NSBundle mainBundle] builtInPlugInsPath];
	if (folderPath) {
		NSEnumerator* enumerator = [[NSBundle pathsForResourcesOfType:@"edplugin"
			inDirectory:folderPath] objectEnumerator];

		NSString* pluginPath;
		while ((pluginPath = [enumerator nextObject])) {
			[self activatePlugin:pluginPath];
		}
	}
	INFO1( @"Packet classes:\n%@", [dissectorDefaultsArray description] );
	INFO1( @"Aggregate classes:\n%@", [aggregateDefaultsArray description] );

	[pluginDefaultsArray addObjectsFromArray:dissectorDefaultsArray];
	[pluginDefaultsArray addObjectsFromArray:aggregateDefaultsArray];
	
	[self didChangeValueForKey:@"dissectorDefaultsArray"];
	[self didChangeValueForKey:@"aggregateDefaultsArray"];
	[self didChangeValueForKey:@"pluginDefaultsArray"];
}

- (void)activatePlugin:(NSString*)path
{
	ENTRY1( @"activatePlugin:%@", path );
	NSBundle* pluginBundle = [NSBundle bundleWithPath:path];

	if (![pluginBundle load]) {
		ERROR( @"failed to load bundle code" );
		return;
	}
	
	DEBUG( @"found & loaded plugin bundle" );
	int count;	
	NSEnumerator *en;
	NSMutableDictionary *tempDict;
	
	en = [[NSArray arrayWithContentsOfFile:
		[pluginBundle pathForResource:@"Dissectors" ofType:@"plist"]
	] objectEnumerator];
	
	count = 0;
	while ( tempDict = [en nextObject] ) {
		[dissectorDefaultsArray addObject:[Plugin registerDissectorAndGetDefaultsWithSettings:tempDict] ];
		count++;
	}
	DEBUG1( @"loaded %d dissectors", count );
	
	en = [[NSArray arrayWithContentsOfFile:
		[pluginBundle pathForResource:@"Aggregators" ofType:@"plist"]
	] objectEnumerator];
	count = 0;
	while ( tempDict = [en nextObject] ) {
		[aggregateDefaultsArray addObject:[Plugin registerAggregateAndGetDefaultsWithSettings:tempDict] ];
	}
	DEBUG1( @"loaded %d aggregators", count );
	
	en = [[NSArray arrayWithContentsOfFile:
		[pluginBundle pathForResource:@"Decoders" ofType:@"plist"]
	] objectEnumerator];
	count = 0;
	while ( tempDict = [en nextObject] ) {
		[decoderDefaultsArray addObject:[Plugin registerDecoderAndGetDefaultsWithSettings:tempDict] ];
	}
	DEBUG1( @"loaded %d decoders", count );
}


- (IBAction)savePluginPreferences:(id)sender
{
	NSEnumerator *en = [pluginDefaultsArray objectEnumerator];
	PluginDefaults *tempDefaults;
	while ( tempDefaults=[en nextObject] ) {
		DEBUG1( @"saving %@", [tempDefaults description] );
		[tempDefaults save:self];
	}
}

- (void)setSelectedDissectorIndexes:(NSIndexSet *)newIndexSet
{
	[selectedDissectorIndexes release];
	selectedDissectorIndexes = [newIndexSet retain];
	
	id pluginDefaults = [pluginsArrayController selection];
	DEBUG1( @"selected defaults: %@", [pluginDefaults description] );
	
	NSView *theView = [pluginDefaults valueForKey:@"defaultsView"];
	if (theView) {
		[dissectorPrefsBox setContentView:theView];
	} else {
		ERROR( @"no view to load" );
	}
}

- (NSIndexSet *)selectedDissectorIndexes
{
	return selectedDissectorIndexes;
}


@end
