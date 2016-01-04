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

+ (ColorizationRules*)sharedRules
{
	if (!sharedRules)
		sharedRules = [[ColorizationRules alloc] init];
	return sharedRules;
}

+ (instancetype)rulesWithDictionary:(NSDictionary *)newRules
{
	return [[[ColorizationRules alloc] initWithRules:newRules] autorelease];
}

+ (ColorizationRules*)sharedRulesWithDictionary:(NSDictionary *)newRules
{
	if (!sharedRules)
		sharedRules = [ColorizationRules sharedRules];
	[sharedRules setRules:newRules];
	return sharedRules;
}

+ (ColorizationRules*)sharedRulesWithDictionary:(NSDictionary *)newRules allowsPartialMatches:(BOOL)allowPartial
{
	if (!sharedRules)
		sharedRules = [ColorizationRules sharedRules];
	[sharedRules setRules:newRules];
	[sharedRules setAllowsPartialMatches:allowPartial];
	return sharedRules;
}

- (instancetype)init
{
	return [self initWithRules:@{} allowsPartialMatches:YES];
}

- (instancetype)initWithRules:(NSDictionary *)newRules
{
	return [self initWithRules:newRules allowsPartialMatches:YES];
}

- (instancetype)initWithRules:(NSDictionary *)newRules allowsPartialMatches:(BOOL)allowPartial
{
	self = [super init];
	if (self) {
		rules = newRules;
		[rules retain];
		cachedResults = [@{} retain];
		allowPartialMatches = allowPartial;
	}
	return self;
}


- (NSColor *)colorForString:(NSString *)string
{
	return rules[string];
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
	tempDict[string] = color;
	
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
	rules = [@{} retain];
}

- (void)resetCachedResults
{
	[cachedResults release];
	cachedResults = [@{} retain];
}

- (void)resetRules
{
	[self removeAllColors];
	[self resetCachedResults];
}


- (NSAttributedString *)colorize:(NSString *)string
{
	NSAttributedString *returnString = cachedResults[string];
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
				setAttributes:@{NSForegroundColorAttributeName: rules[rule]}
				range:[string rangeOfString:rule]
			];
		}
	} else {
		while (rule = [en nextObject]) {
			if ([tempString isEqual:rule]) {
				[tempString
					setAttributes:@{NSForegroundColorAttributeName: rules[rule]}
					range:NSMakeRange(0,string.length)
				];
			}
		}
	}
	
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:cachedResults];
	tempDict[string] = tempString;
	[cachedResults release];
	cachedResults = [tempDict copy];
	[cachedResults retain];
	
	return [tempString copy];
}

@end
