//
//  CaptureDocument.h
//  Eavesdrop
//
//  Created by Eric Baur on Wed Jul 14 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Capture.h"
#import "Conversation.h"
#import "CaptureController.h"

@interface CaptureDocument : NSDocument
{
	IBOutlet NSTableView *unifiedTable;
	IBOutlet NSTableView *dividedTable;
	IBOutlet NSTableView *dataTable;
	
	IBOutlet NSWindow *historyWindow;
	IBOutlet NSWindow *captureWindow;
	IBOutlet NSPanel *settingsPanel;
	
	IBOutlet NSArrayController *conversationController;
	IBOutlet NSArrayController *historyController;
	IBOutlet NSArrayController *imagesController;
	IBOutlet NSObjectController *payloadController;
	
	IBOutlet CaptureController *captureController;

	IBOutlet NSTableView *thumbnailTableView;
	
	IBOutlet NSTextField *filterTextField;
	IBOutlet NSComboBox *interfaceComboBox;
	IBOutlet NSTabView *dataTabView;
	IBOutlet NSTextField *readFilenameField;
	IBOutlet NSTextField *saveFilenameField;
	
	IBOutlet NSPopUpButton *payloadViewPopup;
	IBOutlet NSTextView *payloadTextView;
	
	IBOutlet NSSearchField *packetSearchField;
	//NSMenu *packetSearchMenu;
	
	IBOutlet NSImageView *imageBox;
	
	NSString *readFilename;
	
	NSTimer *checkTimer;
}

- (IBAction)openHistory:(id)sender;
- (IBAction)openSettings:(id)sender;
- (IBAction)closeSettings:(id)sender;

- (IBAction)toggleSelectNew:(id)sender;
- (IBAction)toggleFollowHistory:(id)sender;

- (IBAction)changeThumbnailSize:(id)sender;
- (IBAction)changePayloadView:(id)sender;

- (IBAction)clearList:(id)sender;
- (IBAction)packetsearch:(id)sender;
- (IBAction)changeSearchCategory:(id)sender;

- (IBAction)saveImage:(id)sender;

@end
