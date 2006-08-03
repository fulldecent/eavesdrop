//
//  DetailController.h
//  Eavesdrop
//
//  Created by Eric Baur on 7/27/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <EDPlugin/Plugin.h>

@interface DetailController : NSObject {
	IBOutlet NSWindow *detailWindow;
	IBOutlet NSArrayController *selectedPacketsArrayController;
	IBOutlet NSObjectController *selectedObjectController;

	IBOutlet NSTableView *packetTableView;
	IBOutlet NSPopUpButton *payloadDisplayTypes;
	IBOutlet NSPopUpButton *payloadDisplaySubTypes;
	IBOutlet NSBox *pluginsBox;

	Plugin *selectedObject;
}

- (void)updatePluginBox;
- (void)updateTableView;

@end
