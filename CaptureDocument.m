//
//  CaptureDocument.m
//  Eavesdrop
//
//  Created by Eric Baur on Wed Jul 14 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

#import "CaptureDocument.h"

@implementation CaptureDocument

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"CaptureDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)docType
{
	return NO;
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
	readFilename = fileName;
	[readFilename retain];
	return YES;
}

- (void)awakeFromNib
{
	unifiedTable.target = self;
	unifiedTable.doubleAction = @selector(openHistory:);
	
	dividedTable.target = self;
	dividedTable.doubleAction = @selector(openHistory:);
	
	dataTable.target = self;
	dataTable.doubleAction = @selector(openHistory:);

	[captureController setTables:@[unifiedTable, dividedTable, dataTable] ];
	
	NSArray *tempArray = [Capture interfaces];
	NSEnumerator *en = [tempArray objectEnumerator];
	NSString *tempString;
	while (tempString = [en nextObject]) {
		[interfaceComboBox addItemWithObjectValue:tempString];
	}
	interfaceComboBox.stringValue = tempArray[0] ;
	
	if (readFilename) {
		[captureController setReadFilename:readFilename];
		readFilenameField.stringValue = readFilename;
		[dataTabView selectTabViewItemWithIdentifier:@"offline"];
	}

	// set up the packetSearch field with its default menu	
	NSMenu *packetSearchMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];

	int i=0;
    NSMenuItem *item;
    id searchCell = packetSearchField.cell;
	//item = [[NSMenuItem alloc] initWithTitle:@"Intelligent Search"
	//							action:@selector(changeSearchCategory:)
	//							keyEquivalent:@""];
	//[item setState:NSOnState];
	//[packetSearchMenu insertItem:item atIndex:i++];
	item = [[NSMenuItem alloc] initWithTitle:@"Hosts"
								action:nil
								keyEquivalent:@""];
	[packetSearchMenu insertItem:item atIndex:i++];
	item = [[NSMenuItem alloc] initWithTitle:@"  Either IP"
								action:@selector(changeSearchCategory:)
								keyEquivalent:@""];
	item.state = NSOnState;
    item.tag = CCHostIPSearchTag;
	[packetSearchMenu insertItem:item atIndex:i++];
	item = [[NSMenuItem alloc] initWithTitle:@"  Client IP"
								action:@selector(changeSearchCategory:)
								keyEquivalent:@""];
    item.tag = CCClientIPSearchTag;
	[packetSearchMenu insertItem:item atIndex:i++];
	item = [[NSMenuItem alloc] initWithTitle:@"  Server IP"
								action:@selector(changeSearchCategory:)
								keyEquivalent:@""];
    item.tag = CCServerIPSearchTag;
	[packetSearchMenu insertItem:item atIndex:i++];
	item = [[NSMenuItem alloc] initWithTitle:@"Ports"
								action:nil
								keyEquivalent:@""];
	[packetSearchMenu insertItem:item atIndex:i++];
	item = [[NSMenuItem alloc] initWithTitle:@"  Either Port"
								action:@selector(changeSearchCategory:)
								keyEquivalent:@""];
    item.tag = CCPortSearchTag;
	[packetSearchMenu insertItem:item atIndex:i++];
	item = [[NSMenuItem alloc] initWithTitle:@"  Client Port"
								action:@selector(changeSearchCategory:)
								keyEquivalent:@""];
    item.tag = CCClientPortSearchTag;
	[packetSearchMenu insertItem:item atIndex:i++];
	item = [[NSMenuItem alloc] initWithTitle:@"  Server Port"
								action:@selector(changeSearchCategory:)
								keyEquivalent:@""];
    item.tag = CCServerPortSearchTag;
	[packetSearchMenu insertItem:item atIndex:i++];
	item = [[NSMenuItem alloc] initWithTitle:@"Payloads"
								action:nil
								keyEquivalent:@""];
	[packetSearchMenu insertItem:item atIndex:i++];
	item = [[NSMenuItem alloc] initWithTitle:@"  Either"
								action:@selector(changeSearchCategory:)
								keyEquivalent:@""];
    item.tag = CCPayloadSearchTag;
	[packetSearchMenu insertItem:item atIndex:i++];
	item = [[NSMenuItem alloc] initWithTitle:@"  Client Payload"
								action:@selector(changeSearchCategory:)
								keyEquivalent:@""];
    item.tag = CCClientPayloadSearchTag;
	[packetSearchMenu insertItem:item atIndex:i++];
	item = [[NSMenuItem alloc] initWithTitle:@"  Server Payload"
								action:@selector(changeSearchCategory:)
								keyEquivalent:@""];
    item.tag = CCServerPayloadSearchTag;
	[packetSearchMenu insertItem:item atIndex:i++];
/*
    item = [[NSMenuItem alloc] initWithTitle:@"Recent Searches"
                                action:NULL
                                keyEquivalent:@""];
    [item setTag:NSSearchFieldRecentsTitleMenuItemTag];
    [packetSearchMenu insertItem:item atIndex:i++];
    [item release];
    item = [[NSMenuItem alloc] initWithTitle:@"Recents"
                                action:NULL
                                keyEquivalent:@""];
    [item setTag:NSSearchFieldRecentsMenuItemTag];
    [cellMenu insertItem:item atIndex:i++];
    [item release];
	[packetSearchMenu insertItem:[NSMenuItem separatorItem] atIndex:i++];
    item = [[NSMenuItem alloc] initWithTitle:@"Clear"
                                action:NULL
                                keyEquivalent:@""];
    [item setTag:NSSearchFieldClearRecentsMenuItemTag];
    [packetSearchMenu insertItem:item atIndex:i++];
    [item release];
*/
    [searchCell setSearchMenuTemplate:packetSearchMenu];
}

- (IBAction)openHistory:(id)sender
{
	[historyWindow makeKeyAndOrderFront:self];
}

- (IBAction)openSettings:(id)sender
{
	[NSApp
		beginSheet:settingsPanel
		modalForWindow:captureWindow
		modalDelegate:nil
		didEndSelector:nil
		contextInfo:nil
	];
}

- (IBAction)closeSettings:(id)sender
{
	[NSApp endSheet:settingsPanel];
	[settingsPanel orderOut:self];
	[settingsPanel makeFirstResponder:settingsPanel];   //this is to force the textField to update
}

- (IBAction)stopCapture:(id)sender
{
	[captureController stopCapture:self];
	
	[sender setTitle:@"Start Capture"];
	[sender setAction:@selector(startCapture:)];
}

- (IBAction)toggleSelectNew:(id)sender
{
	conversationController.selectsInsertedObjects = [sender state];
}

- (IBAction)toggleFollowHistory:(id)sender
{
	historyController.selectsInsertedObjects = [sender state];
}

- (IBAction)toggleRequiresSyn:(id)sender
{	//this needs to change (it shouldn't be global, but it is)
	[Conversation setRequiresSyn:[sender state] ];
}

- (IBAction)changeThumbnailSize:(id)sender
{
	thumbnailTableView.rowHeight = [sender intValue] ;
}

- (IBAction)changePayloadView:(id)sender
{
	ENTRY(NSLog( @"[CaptureDocument changePayloadView:]" ));
	switch(payloadViewPopup.selectedItem.tag) {
		case CCAnyHostTag:
			[payloadTextView bind:@"data" toObject:conversationController
				withKeyPath:@"selection.payloadAsRTFData" options:nil ];
			break;
		case CCClientHostTag:
			[payloadTextView bind:@"data" toObject:conversationController
				withKeyPath:@"selection.clientPayloadAsRTFData" options:nil ];
			break;
		case CCServerHostTag:
			[payloadTextView bind:@"data" toObject:conversationController
				withKeyPath:@"selection.serverPayloadAsRTFData" options:nil ];
			break;
		default:
			NSLog( @"No valid payload view specified." );
	}
}

- (IBAction)clearList:(id)sender
{
	[conversationController removeObjectsAtArrangedObjectIndexes:[NSIndexSet
		indexSetWithIndexesInRange:NSMakeRange(0,[conversationController.arrangedObjects count])]
	];
}

- (IBAction)packetsearch:(id)sender
{
	[captureController searchForString:[sender stringValue] ];
}

- (IBAction)changeSearchCategory:(id)sender
{
	[[sender menu] itemWithTag:[captureController searchCategory]].state = NSOffState;
	[sender setState:NSOnState];
	[captureController setSearchCategory:[sender tag] ];
}

- (id)valueForUndefinedKey:(NSString *)key
{
	return nil;
}

/* added by Will Darling - feb. 24 */
/* save the image that's currently in the imagewell as a tiff */
- (IBAction)saveImage:(id)sender
{
	NSData *imgAsData;
	NSSavePanel *sp;
	
	imgAsData = imageBox.image.TIFFRepresentation;
	
	sp = [NSSavePanel savePanel];
	[sp setRequiredFileType:@"tiff"];
	[sp beginSheetForDirectory:NSHomeDirectory() file:@""
		modalForWindow:historyWindow
		modalDelegate:nil
		didEndSelector:nil
		contextInfo:nil
	];
	
	if([sp runModal] == NSFileHandlingPanelOKButton)
	{
		NSString *path = [sp filename];
		[imgAsData writeToFile:path atomically:YES];
	}
}


@end
