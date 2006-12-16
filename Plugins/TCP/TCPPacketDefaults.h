//
//  TCPPacketDefaults.h
//  Eavesdrop
//
//  Created by Eric Baur on 7/11/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <EDPlugin/PluginDefaults.h>

@interface TCPPacketDefaults : PluginDefaults {
	NSMutableArray *flagsArray;
	NSMutableArray *flagGroupsArray;
	
	id currentFlagSelection;
	
	BOOL flagsOverlayGroup;
	
	IBOutlet NSSegmentedControl *flagsSegmentedControl;
	IBOutlet NSArrayController *flagGroupsArrayController;
	
	IBOutlet NSTableView *flagGroupsTableView;
}

- (NSMutableArray *)flagsArray;
- (NSMutableDictionary *)flagsDictionary;
- (NSDictionary *)flagGroupsDictionary;

- (void)setFlags:(NSString *)flags;

- (IBAction)changeFlags:(id)sender;

@end
