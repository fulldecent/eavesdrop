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
	ENTRY( @"updatePluginBox" );
	
	NSView *payloadView = [selectedObject valueForKey:@"payloadView"];
	INFO( [payloadView description] );
	
	[pluginsBox setContentView:payloadView];
}

- (void)updateTableView
{

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
