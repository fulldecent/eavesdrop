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
	}
	return self;
}

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
	ENTRY( @"updatePluginBox" );

	[viewInfoArray removeAllObjects];
	
	NSEnumerator *tempEn = [[selectedObject valueForKey:@"registeredDecoders"] objectEnumerator];
	id tempViewInfo;
	while ( tempViewInfo=[tempEn nextObject] ) {
		Class<Decoder> tempClass = [tempViewInfo valueForKey:@"decoderClassName"];
		if ( [tempClass canDecodePayload:[selectedObject valueForKey:@"payloadData"] ] ) {
			DEBUG1( @"canDecodePayload: returns true for %@", [tempViewInfo valueForKey:@"decoderClassName"] );
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
		while ( tempDict=[en nextObject] ) {
			[menu addItemWithTitle:[tempDict objectForKey:@"name"] action:nil keyEquivalent:@""];
			
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
	pluginDisplayIndex = newDisplayIndex;

	DEBUG1( @"setPluginDisplayIndex: %d", newDisplayIndex );

	NSTabViewItem *tabViewItem = [pluginsTabView tabViewItemAtIndex:pluginDisplayIndex];

	if ( newDisplayIndex >= [viewInfoArray count] ) {
		DEBUG( @"do decoder found" );
		[tabViewItem setView:blankView];
		return;	
	}

	NSDictionary *decoderInfo = [viewInfoArray objectAtIndex:newDisplayIndex];
	Class tempClass = [decoderInfo valueForKey:@"decoderClassName"];

	NSData *tempData = [selectedObject valueForKey:@"payloadData"];
	if (tempData) {
		[selectedDecoder release];
		selectedDecoder = [[tempClass alloc] initWithPayload:tempData ];
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
