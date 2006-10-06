//
//  DetailController.m
//  Eavesdrop
//
//  Created by Eric Baur on 7/27/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "DetailController.h"


@implementation DetailController

#pragma mark -
#pragma mark Setup/destruction methods

- (void)awakeFromNib
{
	ENTRY( @"awakeFromNib" );

	[selectedObjectController addObserver:self forKeyPath:@"selection" options:nil context:nil];
}

- (void)dealloc
{
	[selectedObjectController removeObserver:self forKeyPath:@"selection"];
	[super dealloc];
}

#pragma mark -
#pragma mark Update UI elements

- (void)updatePluginBox
{
	NSArray *viewsInfoArray = [selectedObject valueForKey:@"payloadViewArray"];
	INFO1( @"updatePluginBox:\n%@", [viewsInfoArray description] );
	
	if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"payloadViewAsTabs"] boolValue]) {
		[payloadViewsPopup setHidden:TRUE];
		[pluginsTabView setTabViewType:NSTopTabsBezelBorder];
	} else {
		[payloadViewsPopup setHidden:NO];
		[pluginsTabView setTabViewType:NSNoTabsBezelBorder];
	}
	
	NSMenu *menu = [payloadViewsPopup menu];
	NSEnumerator *en = [[menu itemArray] objectEnumerator];
	id item;
	while ( item=[en nextObject] ) {
		[menu removeItem:item];
	}
	
	en = [[pluginsTabView tabViewItems] objectEnumerator];
	while ( item=[en nextObject] ) {
		[pluginsTabView removeTabViewItem:item];
	}

	en = [viewsInfoArray objectEnumerator];
	NSDictionary *tempDict;
	NSTabViewItem *tempItem;
	while ( tempDict=[en nextObject] ) {
		[menu addItemWithTitle:[tempDict objectForKey:@"name"] action:nil keyEquivalent:@""];
		
		tempItem = [[[NSTabViewItem alloc] initWithIdentifier:nil] autorelease];
		[tempItem setLabel:[tempDict objectForKey:@"name"] ];
		[tempItem setView:[selectedObject valueForKey:[tempDict valueForKey:@"viewKey"]] ];
		[pluginsTabView addTabViewItem:tempItem];
	}
	
	if ( [[menu itemArray] count]==0 ) {
		[payloadViewsPopup setHidden:YES];
		[pluginsTabView setHidden:YES];
	} else {
		[payloadViewsPopup setHidden:NO];
		[pluginsTabView setHidden:NO];
	}
}

- (void)updateTableView
{
	ENTRY( @"updateTableView" );
	NSArray *detailColumnsArray = [selectedObject valueForKey:@"detailColumnsArray"];

	NSEnumerator *en = [[packetTableView tableColumns] objectEnumerator];
	NSTableColumn *tempColumn;
	while ( tempColumn=[en nextObject] ) {
		[packetTableView removeTableColumn:tempColumn];
	}
	
	en = [detailColumnsArray objectEnumerator];
	while ( tempColumn=[en nextObject] ) {
		[tempColumn
			bind:NSValueBinding
			toObject:selectedPacketsArrayController
			withKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", [tempColumn identifier]]
			options:nil
		];
		[packetTableView addTableColumn:tempColumn];
	}
	
	//INFO1( @"detailColumnsArray: %@", [detailColumnsArray description] );
}

#pragma mark -
#pragma mark Observer methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	ENTRY( @"observeValueForKeyPath:ofObject:change:context:" );
	[selectedObject release];
	selectedObject = [[object valueForKeyPath:keyPath] retain];
	
	[self updatePluginBox];
	[self updateTableView];
}

@end
