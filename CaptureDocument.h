//
//  CaptureDocument.h
//  Eavesdrop
//
//  Created by Eric Baur on 5/16/06.
//  Copyright Eric Shore Baur 2006 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CaptureHandlers.h"

//how's about a better name?
#import "Constants.h"
#import "BHDebug.h"

#import <EDPlugin/Packet.h>
#import <EDPlugin/Dissector.h>
#import "PacketQueue.h"

#import "CaptureThread.h"

@interface CaptureDocument : NSDocument
{
	id serverProxy;
	id collectorProxy;
	id appDelegate;
	
	CaptureThread *fileCaptureThread;
	PacketQueue *packetQueue;
	NSString *identifier;
	NSString *queueIdentifier;
	
	NSString *remoteHostAddress;
	NSString *remoteHostIdentifier;
	
	IBOutlet NSWindow *documentWindow;
	IBOutlet NSWindow *settingsWindow;
	
	NSMutableArray *packetListArray;
	IBOutlet NSArrayController *aggregateArrayController;
	IBOutlet NSTreeController *aggregateTreeController;
	IBOutlet NSOutlineView *packetOutlineView;
	IBOutlet NSDrawer *packetInfoDrawer;
	IBOutlet NSWindow *packetDetailWindow;
	
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

- (IBAction)startCapture:(id)sender;
- (IBAction)stopCapture:(id)sender;
- (IBAction)refreshData:(id)sender;
- (IBAction)updateDetails:(id)sender;
- (IBAction)killServer:(id)sender;

- (IBAction)showSettings:(id)sender;
- (IBAction)saveSettings:(id)sender;

- (IBAction)launchServer:(id)sender;

- (IBAction)chooseFile:(id)sender;

- (IBAction)applyAggregates:(id)sender;

- (void)setCaptureType:(CDCaptureType)newType;
- (int)tableRefresh;
- (void)setTableRefresh:(int)newRefresh;
- (NSString *)aggregate;
- (void)setAggregate:(NSString *)newAggregate;

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
@end
