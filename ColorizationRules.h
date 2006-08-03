//
//  ColorizationRules.h
//  Eavesdrop
//
//  Created by Eric Baur on Fri Jul 23 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ColorizationRules : NSObject {
	NSDictionary *rules;
	NSDictionary *cachedResults;
	
	BOOL allowPartialMatches;
}

+ (id)sharedRules;
+ (id)rulesWithDictionary:(NSDictionary *)newRules;
+ (id)sharedRulesWithDictionary:(NSDictionary *)newRules;
+ (id)sharedRulesWithDictionary:(NSDictionary *)newRules allowsPartialMatches:(BOOL)allowPartial;

- (id)init;
- (id)initWithRules:(NSDictionary *)newRules;
- (id)initWithRules:(NSDictionary *)newRules allowsPartialMatches:(BOOL)allowPartial;

- (NSColor *)colorForString:(NSString *)string;
- (NSArray *)stringsForColor:(NSColor *)color;

- (BOOL)allowsPartialMatches;
- (void)setAllowsPartialMatches:(BOOL)allowPartial;

- (void)addColor:(NSColor *)color forString:(NSString *)string;
- (void)setRules:(NSDictionary *)newRules;
- (void)setRules:(NSDictionary *)newRules clearingCache:(BOOL)clearCache;

- (void)removeColorForString:(NSString *)string;
- (void)removeAllColors;
- (void)resetCachedResults;
- (void)resetRules;

- (NSAttributedString *)colorize:(NSString *)string;
- (NSAttributedString *)_colorize:(NSString *)string;

@end
