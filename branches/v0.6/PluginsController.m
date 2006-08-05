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
	
	//load the Packet Dissector
	[dissectorDefaultsArray addObject:[Dissector registerDissectorAndGetDefaultsWithSettings:
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"Packet",						@"dissectorClassName",
			@"packet",						@"protocol",
			[NSNumber numberWithBool:YES],	@"enabled",
			[NSArchiver archivedDataWithRootObject:[NSColor whiteColor] ],
											@"backgroundColor",
			[NSArchiver archivedDataWithRootObject:[NSColor blackColor] ],
											@"textColor",
			nil]
		]
	];
	[aggregateDefaultsArray addObject:[Dissector registerAggregateAndGetDefaultsWithSettings:
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"Aggregate",					@"aggregateClassName",
			@"Packet",						@"dissectorClassName",
			@"None",						@"name",
			[NSNumber numberWithBool:YES],	@"enabled",
			[NSArchiver archivedDataWithRootObject:[NSColor whiteColor] ],
											@"backgroundColor",
			[NSArchiver archivedDataWithRootObject:[NSColor blackColor] ],
											@"textColor",
			nil]
		]
	];

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
/*	
	// need to move this to the right key?
	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
	[defaults setInitialValues:[NSDictionary dictionaryWithObject:dissectorDefaultsArray forKey:@"DissectorPlugins"] ];
	[defaults setInitialValues:[NSDictionary dictionaryWithObject:aggregateDefaultsArray forKey:@"AggregatePlugins"] ];
	
	[defaults save:self];
*/	
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

	if ([pluginBundle load]) {
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
	} else {
		ERROR( @"failed to load bundle code" );
	}
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
	//DEBUG1( @"selected defaults: %@", [pluginDefaults description] );
	
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
