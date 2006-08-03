//
//  ColorizationRules.m
//  Eavesdrop
//
//  Created by Eric Baur on Fri Jul 23 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

#import "ColorizationRules.h"


@implementation ColorizationRules

static id sharedRules;

+ (id)sharedRules
{
	if (!sharedRules)
		sharedRules = [[ColorizationRules alloc] init];
	return sharedRules;
}

+ (id)rulesWithDictionary:(NSDictionary *)newRules
{
	return [[[ColorizationRules alloc] initWithRules:newRules] autorelease];
}

+ (id)sharedRulesWithDictionary:(NSDictionary *)newRules
{
	if (!sharedRules)
		sharedRules = [ColorizationRules sharedRules];
	[sharedRules setRules:newRules];
	return sharedRules;
}

+ (id)sharedRulesWithDictionary:(NSDictionary *)newRules allowsPartialMatches:(BOOL)allowPartial
{
	if (!sharedRules)
		sharedRules = [ColorizationRules sharedRules];
	[sharedRules setRules:newRules];
	[sharedRules setAllowsPartialMatches:allowPartial];
	return sharedRules;
}

- (id)init
{
	return [self initWithRules:[NSDictionary dictionary] allowsPartialMatches:YES];
}

- (id)initWithRules:(NSDictionary *)newRules
{
	return [self initWithRules:newRules allowsPartialMatches:YES];
}

- (id)initWithRules:(NSDictionary *)newRules allowsPartialMatches:(BOOL)allowPartial
{
	self = [super init];
	if (self) {
		rules = newRules;
		[rules retain];
		cachedResults = [[NSDictionary dictionary] retain];
		allowPartialMatches = allowPartial;
	}
	return self;
}


- (NSColor *)colorForString:(NSString *)string
{
	return [rules objectForKey:string];
}

- (NSArray *)stringsForColor:(NSColor *)color
{
	return [rules allKeysForObject:color];
}

- (BOOL)allowsPartialMatches
{
	return allowPartialMatches;
}

- (void)setAllowsPartialMatches:(BOOL)allowPartial
{
	allowPartialMatches = allowPartial;
}


- (void)addColor:(NSColor *)color forString:(NSString *)string
{
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:rules];
	[tempDict setObject:color forKey:string];
	
	[rules release];
	rules = [tempDict copy];
	[rules retain];
}

- (void)setRules:(NSDictionary *)newRules
{
	[self setRules:newRules clearingCache:YES];
}

- (void)setRules:(NSDictionary *)newRules clearingCache:(BOOL)clearCache
{
	[rules release];
	rules = newRules;
	[rules retain];
	
	if (clearCache)
		[self resetCachedResults];
}

- (void)removeColorForString:(NSString *)string
{
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:cachedResults];
	[tempDict removeObjectForKey:string];
	[cachedResults release];
	cachedResults = [tempDict copy];
	[cachedResults retain];
}

- (void)removeAllColors
{
	[rules release];
	rules = [[NSDictionary dictionary] retain];
}

- (void)resetCachedResults
{
	[cachedResults release];
	cachedResults = [[NSDictionary dictionary] retain];
}

- (void)resetRules
{
	[self removeAllColors];
	[self resetCachedResults];
}


- (NSAttributedString *)colorize:(NSString *)string
{
	NSAttributedString *returnString = [cachedResults objectForKey:string];
	if (!returnString)
		returnString = [self _colorize:string];

	return returnString;
}

- (NSAttributedString *)_colorize:(NSString *)string
{
	NSMutableAttributedString *tempString = [[NSMutableAttributedString alloc] initWithString:string];
	NSEnumerator *en = [rules keyEnumerator];
	NSString *rule;
	if (allowPartialMatches) {
		while (rule = [en nextObject]) {
			[tempString
				setAttributes:[NSDictionary dictionaryWithObject:[rules objectForKey:rule] forKey:NSForegroundColorAttributeName]
				range:[string rangeOfString:rule]
			];
		}
	} else {
		while (rule = [en nextObject]) {
			if ([tempString isEqual:rule]) {
				[tempString
					setAttributes:[NSDictionary dictionaryWithObject:[rules objectForKey:rule] forKey:NSForegroundColorAttributeName]
					range:NSMakeRange(0,[string length])
				];
			}
		}
	}
	
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:cachedResults];
	[tempDict setObject:tempString forKey:string];
	[cachedResults release];
	cachedResults = [tempDict copy];
	[cachedResults retain];
	
	return [tempString copy];
}

@end
