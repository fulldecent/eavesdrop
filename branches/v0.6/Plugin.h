//
//  Plugin.h
//  Eavesdrop
//
//  Created by Eric Baur on 7/18/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BHLogger/BHLogging.h>

#import "PluginDefaults.h"

@protocol Plugin

#pragma mark META-DATA
+ (NSDictionary *)keyNames;															/* REQUIRED */

+ (NSArray *)keys;																	/* FREEBIE	*/
- (NSArray *)allKeys;																/* FREEBIE	*/
- (NSDictionary *)allKeyNames;														/* FREEBIE	*/

#pragma mark PROPERTIES
- (NSNumber *)number;																/* FREEBIE  */
- (id)sourceString;																	/* RECOMMENDED */
- (id)destinationString;															/* RECOMMENDED */
- (id)typeString;																	/* RECOMMENDED */
- (id)infoString;																	/* RECOMMENDED */
- (id)flagsString;																	/* RECOMMENDED */
- (id)descriptionString;															/* RECOMMENDED */

- (NSString *)protocolString;														/* REQUIRED */

#pragma mark COLLECTIONS
- (NSArray *)detailsArray;															/* FREEBIE	*/
- (NSArray *)detailsTreeArray;														/* FREEBIE  */
- (NSDictionary *)detailsDictionary;												/* FREEBIE	*/
- (NSArray *)protocolsArray;														/* FREEBIE	*/

#pragma mark VIEW METHODS
- (NSArray *)payloadViewArray;

@end


@interface Plugin : NSObject <Plugin> {
	int pluginNumber;
}

#pragma mark REGISTRATION METHODS
+ (id)registerDissectorAndGetDefaultsWithSettings:(NSDictionary *)defaultSettings;
+ (void)_registerDissector:(Class)dissector withSettings:(NSDictionary *)defaultSettings;

+ (id)registerAggregateAndGetDefaultsWithSettings:(NSDictionary *)defaultSettings;
+ (void)_registerAggregate:(Class)aggregateClass withSettings:(NSDictionary *)defaultSettings;

+ (id)registerDecoderAndGetDefaultsWithSettings:(NSDictionary *)defaultSettings;
+ (void)_registerDecoder:(Class)decoderClass withSettings:(NSDictionary *)defaultSettings;

+ (Class)dissectorClassForProtocol:(NSString *)protoName;
+ (PluginDefaults *)pluginDefaultsForClass:(Class)pluginClass;
+ (PluginDefaults *)pluginDefaultsForClassName:(NSString *)pluginClassName;

+ (NSDictionary *)registeredDissectors;
- (NSDictionary *)registeredDissectors;
+ (NSDictionary *)registeredAggregators;
- (NSDictionary *)registeredAggregators;
+ (NSDictionary *)registeredDecoders;
- (NSDictionary *)registeredDecoders;


@end
