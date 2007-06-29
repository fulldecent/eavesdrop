//
//  PluginDefaults.h
//  Eavesdrop
//
//  Created by Eric Baur on 7/9/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BHLogger/BHLogging.h>

@interface PluginDefaults : NSObject {
	NSColor *textColor;
	NSColor *backgroundColor;
	
	NSString *dissectorClassName;
	NSString *aggregateClassName;
	NSString *decoderClass;
	NSString *protocol;
	NSString *name;
	
	NSArray *decodes;
	
	IBOutlet NSView *defaultsView;
	
	BOOL enabled;
}

+ (id)pluginDefaultsWithSettings:(NSDictionary *)settingsDict;

- (id)initWithSettings:(NSDictionary *)settingsDict;
- (NSString *)primaryClassName;

- (void)setInitialDefaults;
- (void)getDefaultValues;
- (void)getDefaultsFromDictionary:(NSDictionary *)defaultsDict;
- (NSDictionary *)defaultsDict;
- (IBAction)save:(id)sender;

- (NSView *)defaultsView;

@end
