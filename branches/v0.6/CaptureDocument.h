//
//  CaptureDocument.h
//  Eavesdrop
//
//  Created by Eric Baur on 5/16/06.
//  Copyright Eric Shore Baur 2006 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <RBSplitView/RBSplitView.h>
#import <RBSplitView/RBSplitSubview.h>

#import "CaptureHandlers.h"

//how's about a better name?
#import "Constants.h"

#import <EDPlugin/Packet.h>
#import <EDPlugin/Dissector.h>
#import "PacketQueue.h"

#import "CaptureThread.h"

#define EDPacketsPboardType			@"EavesdropPackets"
#define EDPacketSourcePboardType	@"EavesdropPacketSource"

@interface CaptureDocument : NSDocument
{
	id serverProxy;
	id collectorProxy;
	id appDelegate;
	
	CaptureThread *fileSaver;
	CaptureThread *fileCaptureThread;
	PacketQueue *packetQueue;
	NSString *identifier;
	NSString *queueIdentifier;
	
	NSString *remoteHostAddress;
	NSString *remoteHostIdentifier;
	
	IBOutlet NSWindow *documentWindow;
	IBOutlet NSWindow *settingsWindow;
	
	NSMutableArray *packetList;
	NSMutableArray *leftoverPacketList;
	IBOutlet NSArrayController *aggregateArrayController;
	IBOutlet NSTreeController *aggregateTreeController;
	IBOutlet NSOutlineView *packetOutlineView;
	IBOutlet NSOutlineView *leftoverOutlineView;
	IBOutlet NSDrawer *packetInfoDrawer;
	IBOutlet NSWindow *packetDetailWindow;
	
	IBOutlet RBSplitView *packetSplitView;
	
	Packet *selectedPacket;
	NSArray *packetDetailsArray;

	CDCaptureType captureType;
	int refreshMilliseconds;
	NSTimer *tableTimer;
	BOOL aggregateUsed;
	BOOL isRefreshing;
}

- (void)setDefaults;
- (PacketQueue *)packetQueue;

- (IBAction)connectToCaptureServer:(id)sender;

- (IBAction)startSave:(id)sender;
- (IBAction)startCapture:(id)sender;
- (IBAction)stopCapture:(id)sender;
- (IBAction)refreshData:(id)sender;
- (IBAction)killServer:(id)sender;

- (IBAction)showSettings:(id)sender;
- (IBAction)saveSettings:(id)sender;

- (IBAction)launchServer:(id)sender;

- (IBAction)chooseFile:(id)sender;

- (IBAction)applyAggregates:(id)sender;

- (void)updateDetailsFromMainOutlineView;
- (void)updateDetailsFromLeftoverOutlineView;
- (void)updateDetailsFromOutlineView:(NSOutlineView *)sourceOutlineView;

- (void)setCaptureType:(CDCaptureType)newType;
- (int)tableRefresh;
- (void)setTableRefresh:(int)newRefresh;
- (NSString *)aggregate;
- (void)setAggregate:(NSString *)newAggregate;
//- (NSString *)subAggregate;
//- (void)setSubAggregate:(NSString *)newAggregate;


- (NSMutableArray *)interfaces;
- (NSString *)saveFile;
- (void)setSaveFile:(NSString *)saveFile;
- (NSString *)readFile;
- (void)setReadFile:(NSString *)readFile;
- (NSString *)captureFilter;
- (void)setCaptureFilter:(NSString *)filterString;
- (NSString *)interface;
- (void)setInterface:(NSString *)newInterface;
- (BOOL)promiscuous;
- (void)setPromiscuous:(BOOL)promiscuousMode;
- (BOOL)capturesPayload;
- (void)setCapturesPayload:(BOOL)shouldCapture;
- (BOOL)isActive;

- (void)settingsSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
- (void)chooseFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;

NSFileHandle *NewFileHandleForWritingFile(NSString *dirpath, NSString *basename, NSString *extension, NSString **oFilename);
@end
