//
//  PluginDefaults.m
//  Eavesdrop
//
//  Created by Eric Baur on 7/9/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "PluginDefaults.h"


@implementation PluginDefaults

+ (id)pluginDefaultsWithSettings:(NSDictionary *)settingsDict
{
	ENTRY( @"pluginDefaultsWithSettings:" );
	if ([settingsDict objectForKey:@"defaultsClassName"]) {
		Class defaultsClass = NSClassFromString( [settingsDict objectForKey:@"defaultsClassName"] );
		if (defaultsClass)
			return [[[defaultsClass alloc] initWithSettings:settingsDict] autorelease];
	}
	
	return [[[PluginDefaults alloc] initWithSettings:settingsDict] autorelease];
}

- (NSString *)settingsNibName
{
	return nil;
}

- (id)initWithSettings:(NSDictionary *)settingsDict
{
	ENTRY( @"initWithSettings:" );
	self = [super init];
	if (self) {
		defaultsView = [[NSView alloc] initWithFrame:NSMakeRect(0,0,250,300)];
		
		dissectorClassName = [[settingsDict objectForKey:@"dissectorClassName"] retain];
		aggregateClassName = [[settingsDict objectForKey:@"aggregateClassName"] retain];
		decoderClass = [[settingsDict objectForKey:@"decoderClass"] retain];
		protocol = [[settingsDict objectForKey:@"protocol"] retain];
		name = [[settingsDict objectForKey:@"name"] retain];
		decodes = [[settingsDict objectForKey:@"decodes"] retain];
		
		id colorTemp = [settingsDict objectForKey:@"textColor"];
		if ( [colorTemp isKindOfClass:[NSColor class]] )
			textColor = [colorTemp retain];
		else if (colorTemp)
			textColor = [[NSUnarchiver unarchiveObjectWithData:colorTemp] retain];
		else
			textColor = [[NSColor blackColor] retain];

		colorTemp = [settingsDict objectForKey:@"backgroundColor"];
		if ( [colorTemp isKindOfClass:[NSColor class]] )
			backgroundColor = [colorTemp retain];
		else if (colorTemp)
			backgroundColor = [[NSUnarchiver unarchiveObjectWithData:colorTemp] retain];
		else
			backgroundColor = [[NSColor whiteColor] retain];
			
		if ( [settingsDict objectForKey:@"enabled"] )
			enabled = [[settingsDict objectForKey:@"enabled"] boolValue];
		else
			enabled = YES;
			
		//load the settings NIB, if there is one
		if ( [self settingsNibName] ) {
			DEBUG1( @"loading NIB: %@", [self settingsNibName] );
			if ( ![NSBundle loadNibNamed:[self settingsNibName] owner:self] ) {
				ERROR1( @"failed to load %@ nib", [self settingsNibName] );
			}
		}
		
		[self setInitialDefaults];
		[self getDefaultValues];
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"PluginDefaults: %@", [self primaryClassName] ];
}

- (NSString *)primaryClassName
{
	if (aggregateClassName)
		return aggregateClassName;
	else if (dissectorClassName)
		return dissectorClassName;
	else if (decoderClass)
		return decoderClass;
	else
		return nil;
}

- (void)setInitialDefaults
{
	ENTRY1( @"setInitialDefaults for %@", [self primaryClassName] );
	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
	
	[defaults setInitialValues:[NSDictionary dictionaryWithObject:
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSArchiver archivedDataWithRootObject:textColor], @"textColor",
				[NSArchiver archivedDataWithRootObject:backgroundColor], @"backgroundColor",
				nil
			]
			forKey:[self primaryClassName]
		]
	];
}

- (void)getDefaultValues
{
	ENTRY1( @"getDefaultValues for %@", [self primaryClassName] );
	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];

	NSDictionary *tempDict = [[defaults values] valueForKey:@"EDPlugins" ];	
	[self getDefaultsFromDictionary:[tempDict valueForKey:[self primaryClassName]] ];
}

- (void)getDefaultsFromDictionary:(NSDictionary *)defaultsDict
{
	id tempColor;
	
	tempColor = [defaultsDict valueForKey:@"textColor"];
	if (tempColor) {
		DEBUG1( @"setting textColor for %@", [self primaryClassName] );
		[textColor release];
		textColor = [[NSUnarchiver unarchiveObjectWithData:[defaultsDict valueForKeyPath:@"textColor"]] retain];
	}
	
	tempColor = [defaultsDict valueForKey:@"backgroundColor"];
	if (tempColor) {
		DEBUG1( @"setting backgroundColor for %@", [self primaryClassName] );
		[backgroundColor release];
		backgroundColor = [[NSUnarchiver unarchiveObjectWithData:[defaultsDict valueForKey:@"backgroundColor"]] retain];
	}
}

- (NSDictionary *)defaultsDict
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSArchiver archivedDataWithRootObject:textColor], @"textColor",
		[NSArchiver archivedDataWithRootObject:backgroundColor], @"backgroundColor",
		nil
	];
}

- (IBAction)save:(id)sender
{
	ENTRY1( @"save: for %@", [self primaryClassName] );
	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];

	NSMutableDictionary *values = [defaults values];	
	NSMutableDictionary *pluginValues = [values valueForKey:@"EDPlugins"];
	
	if (!values) {
		ERROR( @"couldn't get defaults values" );
	}
	if (!pluginValues) {
		pluginValues = [NSMutableDictionary dictionary];
	}
	
	[pluginValues setValue:[self defaultsDict] forKeyPath:[self primaryClassName] ];
	[values setValue:pluginValues forKey:@"EDPlugins"];
	
	[defaults save:self];
}

- (NSView *)defaultsView
{
	return defaultsView;
}

- (NSString *)pluginTypeString
{
	if (aggregateClassName) {
		return @"Aggregate";
	} else if (dissectorClassName) {
		return @"Dissector";
	} else {
		return @"<none>";
	}
}


@end
