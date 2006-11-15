//
//  PluginsController.h
//  Eavesdrop
//
//  Created by Eric Baur on 6/6/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <EDPlugin/Packet.h>
#import <EDPlugin/Aggregate.h>
#import <EDPlugin/PluginDefaults.h>

@interface PluginsController : NSObject {
	id appDelegate;

	NSMutableArray* dissectorDefaultsArray;
	NSMutableArray* aggregateDefaultsArray;
	NSMutableArray* decoderDefaultsArray;
	NSMutableArray* pluginDefaultsArray;
	
	IBOutlet NSBox *dissectorPrefsBox;
	IBOutlet NSArrayController *pluginsArrayController;
	
	NSIndexSet *selectedDissectorIndexes;
	PluginDefaults *selectedDefaults;
}

- (void)findAllPlugins;
- (void)activatePlugin:(NSString*)path;

- (IBAction)savePluginPreferences:(id)sender;

@end
