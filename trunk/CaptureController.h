//
//  CaptureController.h
//  Capture
//
//  Created by Eric Baur on Sat Jul 03 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "sniff.h"
#import <pcap.h>
#import <pcap-namedb.h>

#import "Capture.h"
#import "CaptureQueue.h"
#import "Conversation.h"
#import "CaptureGraphController.h"

typedef enum {
	CCIntelligentSearchTag,
	CCHostIPSearchTag,
	CCClientIPSearchTag,
	CCServerIPSearchTag,
	CCPortSearchTag,
	CCClientPortSearchTag,
	CCServerPortSearchTag,
	CCPayloadSearchTag,
	CCClientPayloadSearchTag,
	CCServerPayloadSearchTag
} CCSearchCategory;

typedef enum {
	CCAnyHostTag,
	CCClientHostTag,
	CCServerHostTag
} CCHostCategory;

@interface CaptureController : NSObject
{
	NSMutableDictionary *conversations;
	
	NSArray *conversationArray;
	NSMutableArray *packetArray;
	
	NSTimer *updateTimer;
	NSArray *tableArray;
	
	BOOL updateNeeded;
	BOOL dataQueued;
	
	BOOL removeIdle;
	unsigned int maxIdle;
	BOOL hideIdle, resetHidden;
	unsigned int maxHide;
	NSString *interface;
	BOOL promiscuous;
	BOOL requireSyn;
	BOOL capturesData;
	NSString *filter;
	int updateInterval;
	BOOL showProcessing;
	NSString *readFilename;
	NSString *saveFilename;
	BOOL saveAll;
	NSString *searchString;
	CCSearchCategory searchCategory;

	NSButton *captureButton;

	IBOutlet NSArrayController *conversationController;
	
	NSString *captureQueueIdentifier;
	id captureQueueProxy;
	
	NSString *captureToolIdentifier;
	Capture *captureObject;

	NSMutableArray *packetAdditions;
	NSLock *packetLock;
}

- (id)init;

- (void)setUpdateInterval:(int)newUpdateInterval;
- (void)startTimer;
- (void)setPacketQueueAndLock:(NSDictionary *)aDictionary;
- (void)setReadFilename:(NSString *)newFilename;
- (void)setFollowsInserts:(BOOL)followInserts;
- (BOOL)followsInserts;
- (void)setHideIdle:(BOOL)newSetting;
- (void)setTables:(NSArray *)newTables;
- (CCSearchCategory)searchCategory;
- (void)setSearchCategory:(CCSearchCategory)newSearchCategory;

- (IBAction)flushData:(id)sender;
- (void)addConversations:(NSArray *)newAdditions;
- (void)processRemovals;
- (NSArray *)processSearchOnArray:(NSArray *)targetArray keepMatches:(BOOL)keepMatches;
- (void)searchForString:(NSString *)newSearchString;

- (IBAction)startCapture:(id)sender;
- (IBAction)stopCapture:(id)sender;

- (void)setArrayController:(NSArrayController *)controller;
@end
