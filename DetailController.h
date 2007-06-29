//
//  DetailController.h
//  Eavesdrop
//
//  Created by Eric Baur on 7/27/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//#import <EDPlugin/Plugin.h>
#import <EDPlugin/Decoder.h>

@interface DetailController : NSObject {
	IBOutlet NSWindow *detailWindow;
	IBOutlet NSArrayController *selectedPacketsArrayController;
	IBOutlet NSObjectController *selectedObjectController;

	IBOutlet NSTabView *detailTabView;
	IBOutlet NSTableView *packetTableView;
	IBOutlet NSPopUpButton *payloadViewsPopup;
	IBOutlet NSTabView *pluginsTabView;
	
	IBOutlet NSView *blankView;
	
	NSMutableArray *viewInfoArray;

	Plugin *selectedObject;
	Decoder *selectedDecoder;
	
	int pluginDisplayIndex;
	//NSString *lastPluginName;
	
	BOOL isBuildingPluginList;
	NSMutableArray *selectedPluginsStack;
	NSMutableArray *pluginTags;
}

- (IBAction)updateViews:(id)sender;
- (void)updatePluginBox;
- (void)updateTableView;

- (void)setPluginDisplayIndex:(int)newDisplayIndex;

@end
