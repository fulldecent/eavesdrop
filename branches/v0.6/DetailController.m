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

- (id)init
{
	self = [super init];
	if (self) {
		viewInfoArray = [[NSMutableArray alloc] init];
		isBuildingPluginList = NO;
		selectedPluginsStack = [[NSMutableArray alloc] init];
		pluginTags = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)awakeFromNib
{
	ENTRY( @"awakeFromNib" );

	[selectedObjectController addObserver:self forKeyPath:@"selection" options:0 context:nil];
}

- (void)dealloc
{
	[selectedObjectController removeObserver:self forKeyPath:@"selection"];
	[super dealloc];
}

#pragma mark -
#pragma mark Update UI elements

- (IBAction)updateViews:(id)sender
{
	if ( ![detailWindow isVisible] ) {
		return;
	}
	
	switch ( [[[detailTabView selectedTabViewItem] identifier] intValue] ) {
		case 0:
			DEBUG( @"Info tab showing" );
			break;
		case 1:
			DEBUG( @"Payload tab showing" );
			[self updatePluginBox];
			break;
		case 2:
			DEBUG( @"Packets tab showing" );
			[self updateTableView];
			break;
		default:
			WARNING( @"No valid case found for update switch/case" );
	}
}

- (void)updatePluginBox
{	
	ENTRY( @"updatePluginBox" );
	
	isBuildingPluginList = YES;
	[viewInfoArray removeAllObjects];
	
	NSEnumerator *tempEn = [[selectedObject valueForKey:@"registeredDecoders"] objectEnumerator];
	id tempViewInfo;
	while ( tempViewInfo=[tempEn nextObject] ) {
		Class<Decoder> tempClass = [tempViewInfo valueForKey:@"decoderClass"];
		if ( [tempClass canDecodePayload:[selectedObject valueForKey:@"payloadData"] ] ) {
			[viewInfoArray addObject:tempViewInfo];
		}
	}
	
	INFO1( @"decoders that will display:\n%@", [viewInfoArray description] );
	
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

	if ( [viewInfoArray count]==0 ) {
		[payloadViewsPopup setEnabled:NO];
	} else {
		[payloadViewsPopup setEnabled:YES];
		
		en = [viewInfoArray objectEnumerator];
		NSDictionary *tempDict;
		NSTabViewItem *tempItem;
		NSMenuItem *tempMenuItem;
		while ( tempDict=[en nextObject] ) {
			tempMenuItem = [menu addItemWithTitle:[tempDict objectForKey:@"name"] action:nil keyEquivalent:@""];
			if ( [pluginTags indexOfObject:[tempDict objectForKey:@"decoderClass"]] == NSNotFound ) {
				[pluginTags addObject:[[tempDict objectForKey:@"decoderClass"] className] ];
			}
			[tempMenuItem setTag:[pluginTags indexOfObject:[[tempDict objectForKey:@"decoderClass"] className]] ];
			
			tempItem = [[[NSTabViewItem alloc] initWithIdentifier:nil] autorelease];
			[tempItem setLabel:[tempDict objectForKey:@"name"] ];
			[pluginsTabView addTabViewItem:tempItem];
		}
	}
	
	if ( [[menu itemArray] count]==0 ) {
		[payloadViewsPopup setHidden:YES];
		[pluginsTabView setHidden:YES];
	} else {
		[payloadViewsPopup setHidden:NO];
		[pluginsTabView setHidden:NO];
	}
	
	//set display index based on selectedPluginsStack
	en = [selectedPluginsStack reverseObjectEnumerator];
	id tempClassName;
	BOOL selectionFound = NO;
	while ( tempClassName = [en nextObject] ) {
		int index = [payloadViewsPopup indexOfItemWithTag:[pluginTags indexOfObject:tempClassName] ];
		if ( index != -1 ) {
			DEBUG2( @"found former popup selection %@ at index %d", tempClassName, index );
			[self setPluginDisplayIndex:index];
			selectionFound = YES;
			break;
		}
	}
	if ( ! selectionFound ) {
		[self setPluginDisplayIndex:0]; 
	}
	
	isBuildingPluginList = NO;
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
}

#pragma mark -
#pragma mark Accessor methods

- (void)setPluginDisplayIndex:(int)newDisplayIndex
{
	if ( newDisplayIndex==pluginDisplayIndex )
		return;
	DEBUG1( @"setPluginDisplayIndex: %d", newDisplayIndex );

	pluginDisplayIndex = newDisplayIndex;

	NSTabViewItem *tabViewItem = [pluginsTabView tabViewItemAtIndex:pluginDisplayIndex];

	if ( newDisplayIndex >= [viewInfoArray count] ) {
		DEBUG( @"no decoder found" );
		[tabViewItem setView:blankView];
		return;	
	}

	NSDictionary *decoderInfo = [viewInfoArray objectAtIndex:newDisplayIndex];
	Class tempClass = [decoderInfo valueForKey:@"decoderClass"];

	NSData *tempData = [selectedObject valueForKey:@"payloadData"];
	if (tempData) {
		[selectedDecoder release];
		selectedDecoder = [[tempClass alloc] initWithObject:selectedObject];
	} else {
		ERROR( @"selected object did not return any payload data" );
	}
	
	NSView *tempView = [selectedDecoder valueForKey:[decoderInfo valueForKey:@"viewKey"] ];
	if (tempView) {
		[tabViewItem setView:tempView];
	} else {
		ERROR( @"couldn't set tab view" );
		[tabViewItem setView:blankView];
	}
	
	if ( ! isBuildingPluginList ) {
		if ( selectedDecoder && selectedObject ) {
			// is it okay to remove this every time?
			[selectedPluginsStack removeObject:[selectedDecoder valueForKey:@"className"] ];
			[selectedPluginsStack addObject:[selectedDecoder valueForKey:@"className"] ];
		}
		INFO1( @"selectedPluginsStack =>\n%@", [selectedPluginsStack description] );
	}
}

#pragma mark -
#pragma mark Observer methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	ENTRY( @"observeValueForKeyPath:ofObject:change:context:" );

	[selectedObject release];
	selectedObject = [[object valueForKeyPath:keyPath] retain];

	[self updateViews:self];
}

//only need one of these, not sure which one is best
// we'll use this one for now...
- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	[self updateViews:self];
}

/*
- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	[self updateViews:self];
}
*/

- (void)windowDidExpose:(NSNotification *)aNotification
{
	ENTRY( @"windowDidExpose:" );
}

#pragma mark -
#pragma mark NSTabView delegate methods

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	[self updateViews:self];
}


@end
