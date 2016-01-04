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

+ (ColorizationRules*)sharedRules;
+ (instancetype)rulesWithDictionary:(NSDictionary *)newRules;
+ (ColorizationRules*)sharedRulesWithDictionary:(NSDictionary *)newRules;
+ (ColorizationRules*)sharedRulesWithDictionary:(NSDictionary *)newRules allowsPartialMatches:(BOOL)allowPartial;

- (instancetype)init;
- (instancetype)initWithRules:(NSDictionary *)newRules;
- (instancetype)initWithRules:(NSDictionary *)newRules allowsPartialMatches:(BOOL)allowPartial NS_DESIGNATED_INITIALIZER;

- (NSColor *)colorForString:(NSString *)string;
- (NSArray *)stringsForColor:(NSColor *)color;

@property (NS_NONATOMIC_IOSONLY) BOOL allowsPartialMatches;

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
