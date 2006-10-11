//
//  Plugin.m
//  Eavesdrop
//
//  Created by Eric Baur on 7/18/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "Plugin.h"


@implementation Plugin

static int pluginCount;

static NSMutableDictionary *registeredDissectors;
static NSMutableDictionary *registeredProtocolClasses;
static NSMutableDictionary *registeredAggregators;
static NSMutableDictionary *registeredDefaults;

+ (void)initialize
{
	ENTRY( @"initialize" );
	if ( (self = [Plugin class]) && !registeredDissectors ) {
		pluginCount = 0;
		
		registeredDissectors = [[NSMutableDictionary alloc] init];
		registeredProtocolClasses = [[NSMutableDictionary alloc] init];
		registeredAggregators = [[NSMutableDictionary alloc] init];
		registeredDefaults = [[NSMutableDictionary alloc] init];

		[Plugin registerDissectorAndGetDefaultsWithSettings:[NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"Plugin",					@"dissectorClassName",
			@"",						@"protocol",
			[NSDictionary dictionary],	@"detailColumns",
			[NSArray array],			@"decodes",
			nil]
		];
	}
}

#pragma mark -
#pragma mark Protocol Class methods

+ (id)registerDissectorAndGetDefaultsWithSettings:(NSDictionary *)defaultSettings
{
	PluginDefaults *pluginDefaults = [PluginDefaults pluginDefaultsWithSettings:defaultSettings];
	[registeredDefaults setObject:pluginDefaults forKey:[pluginDefaults primaryClassName] ];
	
	[self
		_registerDissector:NSClassFromString( [pluginDefaults valueForKey:@"dissectorClassName"] )
		withSettings:defaultSettings
	];
		
	return pluginDefaults;
}

+ (void)_registerDissector:(Class)dissector withSettings:(NSDictionary *)defaultSettings
{
	NSString *protoName = [defaultSettings valueForKey:@"protocol"];

	ENTRY2( @"_registerDissector:%@ forProtocol:%@ decodes:(...)", [dissector className], protoName );
	INFO1( @"decodes array:\n%@", [[defaultSettings valueForKey:@"decodes"] description] );

	if ( [registeredDissectors objectForKey:protoName] ) {
		WARNING1( @"key already exists: %@", protoName );
		return;
	}

	/* need to do something slightly different */
	NSArray *detailColumns = [defaultSettings valueForKey:@"detailColumns"];
	if (!detailColumns)
		detailColumns = [NSArray array];
		
	NSMutableDictionary *tempKeyNames = [NSMutableDictionary dictionary];
	NSEnumerator *en = [detailColumns objectEnumerator];
	id tempDict;
	while ( tempDict=[en nextObject] ) {
		[tempKeyNames setObject:[tempDict objectForKey:@"name"] forKey:[tempDict objectForKey:@"columnKey"] ];
	}
	NSDictionary *keyNames = [tempKeyNames copy];

	NSMutableArray *blankArray = [[[NSMutableArray alloc] init] autorelease];
	//this creates a node for the new dissector
	[registeredDissectors
		setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
			dissector,									@"dissectorClassName",
			[defaultSettings valueForKey:@"protocol"],	@"protocol",
			[defaultSettings valueForKey:@"decodes"],	@"decodes",
			detailColumns,								@"detailColumns",
			blankArray,									@"subDissectors",
			keyNames,									@"keyNames",
			nil
		]
		forKey:protoName
	];
	[registeredProtocolClasses setObject:protoName forKey:dissector ];
	INFO( [[registeredDissectors objectForKey:protoName] description] );

	en = [[defaultSettings valueForKey:@"decodes"] objectEnumerator];
	NSString *tempString;
	while ( tempString=[en nextObject] ) {
		NSMutableDictionary *tempDict = [registeredDissectors objectForKey:tempString];
		NSMutableArray *tempArray = [tempDict objectForKey:@"subDissectors"];
		if (!tempArray) {
			tempArray = [NSMutableArray arrayWithObject:protoName];
			[tempDict setObject:tempArray forKey:@"subDissectors"];
		}
		[tempArray addObject:protoName];
	}
}

+ (id)registerAggregateAndGetDefaultsWithSettings:(NSDictionary *)defaultSettings
{
	PluginDefaults *pluginDefaults = [PluginDefaults pluginDefaultsWithSettings:defaultSettings];
	[registeredDefaults setObject:pluginDefaults forKey:[pluginDefaults valueForKey:@"aggregateClassName"] ];
	
	[NSClassFromString( [pluginDefaults valueForKey:@"dissectorClassName"] )
		_registerAggregate:NSClassFromString( [pluginDefaults valueForKey:@"aggregateClassName"] )
		withSettings:defaultSettings
	];
	
	return pluginDefaults;
}

+ (void)_registerAggregate:(Class)aggregateClass withSettings:(NSDictionary *)defaultSettings
{
	ENTRY2( @"_registerAggregate:%@ withName:%@", [aggregateClass className], [defaultSettings valueForKey:@"name"] );
	[registeredAggregators
		setObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[self className],									@"dissectorClassName",
			[defaultSettings valueForKey:@"name"],				@"name",
			aggregateClass,										@"aggregateClassName",
			[defaultSettings valueForKey:@"payloadViews"],		@"payloadViews",
			[defaultSettings valueForKey:@"primaryProtocol"],	@"primaryProtocol",
			nil
		]
		forKey:[aggregateClass className]
	];
	INFO( [[registeredAggregators objectForKey:[aggregateClass className]] description] );
}

+ (Class)dissectorClassForProtocol:(NSString *)protoName
{
	return [[registeredDissectors objectForKey:protoName] objectForKey:@"class"];
}

+ (PluginDefaults *)pluginDefaultsForClass:(Class)pluginClass
{
	return [registeredDefaults objectForKey:[pluginClass className] ];
}

+ (PluginDefaults *)pluginDefaultsForClassName:(NSString *)pluginClassName
{
	return [registeredDefaults objectForKey:pluginClassName];
}

+ (NSDictionary *)registeredDissectors
{
	return registeredDissectors;
}

+ (NSDictionary *)registeredAggregators
{
	return registeredAggregators;
}

- (NSDictionary *)registeredDissectors
{
	return registeredDissectors;
}

- (NSDictionary *)registeredAggregators
{
	return registeredAggregators;
}

+ (BOOL)canDecodePacket:(NSObject<Plugin> *)testPacket
{
	return YES;
}

#pragma mark -
#pragma mark Setup methods

- (id)init
{
	self = [super init];
	if (self) {
		pluginNumber = ++pluginCount;
	}
	return self;
}

#pragma mark -
#pragma mark View Methods

- (NSArray *)payloadViewArray
{
	return nil;
}

#pragma mark -
#pragma mark Protocol Instance methods

- (NSNumber *)number
{
	NSNumber *tempValue = [self valueForUndefinedKey:@"number"];
	if (tempValue)
		return tempValue;
	else
		return [NSNumber numberWithInt:pluginNumber];
}

- (NSString *)sourceString
{
	NSString *tempValue = [self valueForUndefinedKey:@"sourceString"];
	if (tempValue)
		return tempValue;
	else
		return @"sourceString";
}

- (NSString *)destinationString
{
	NSString *tempValue = [self valueForUndefinedKey:@"destinationString"];
	if (tempValue)
		return tempValue;
	else
		return @"destinationString";
}

- (NSString *)typeString
{
	NSString *tempValue = [self valueForUndefinedKey:@"destinationString"];
	if (tempValue)
		return tempValue;
	else
		return @"typeString";
}

- (NSString *)infoString
{
	NSString *tempValue = [self valueForUndefinedKey:@"infoString"];
	if (tempValue)
		return tempValue;
	else
		return @"infoString";
}

- (NSString *)flagsString
{
	NSString *tempValue = [self valueForUndefinedKey:@"flagsString"];
	if (tempValue)
		return tempValue;
	else
		return @"flagsString";
}

- (NSString *)descriptionString
{
	NSString *tempValue = [self valueForUndefinedKey:@"descriptionString"];
	if (tempValue)
		return tempValue;
	else
		return @"descriptionString";
}

- (NSString *)protocolString
{
	return @"";
}

#pragma mark -
#pragma mark Meta data

+ (NSDictionary *)keyNames
{	//ENTRY( @"keyNames" );
	return [
		[registeredDissectors objectForKey:
			[registeredProtocolClasses objectForKey:
				[self class]] ]
		valueForKey:@"keyNames"
	];
}

+ (NSArray *)keys
{	//ENTRY( @"keys" );
	return [[self keyNames] allKeys];
}

- (NSArray *)allKeys
{	//ENTRY( @"allKeys" );
	return [[self allKeyNames] allKeys];
}

- (NSDictionary *)allKeyNames
{
	NSMutableDictionary *tempDict = [[[self class] keyNames] mutableCopy];
	return [tempDict copy];
}

- (NSArray *)detailsArray
{
	NSMutableArray *tempArray = [NSMutableArray array];
	NSEnumerator *en = [[self allKeys] objectEnumerator];
	NSDictionary *keyNames = [self allKeyNames];
	NSString *tempKey;
	while ( tempKey = [en nextObject] ) {
		[tempArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[keyNames objectForKey:tempKey],	@"name",
				[self valueForKey:tempKey],			@"value",
				nil
			]
		];
	}
	return [tempArray copy];
}

- (NSDictionary *)detailsDictionary
{	//ENTRY( @"detailsDictionary" );
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
	NSEnumerator *en = [[self allKeys] objectEnumerator];
	NSString *tempKey;
	id value;
	while ( tempKey = [en nextObject] ) {
		value = [self valueForKey:tempKey];
		if (value)
			[tempDict setObject:[self valueForKey:tempKey] forKey:tempKey];
		else
			WARNING1( @"key has no value: %@", tempKey );
	}
	return [tempDict copy];
}

- (NSArray *)protocolsArray
{
	NSMutableArray *tempArray = [NSMutableArray array];
	[tempArray addObject:[self protocolString] ];
	return [tempArray copy];
}

#pragma mark -
#pragma mark Overriden methods

- (id)valueForUndefinedKey:(NSString *)key
{
	return nil;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"Class => %@\tdetails => %@",
		[self className],
		[self detailsDictionary]
	];
}

@end
