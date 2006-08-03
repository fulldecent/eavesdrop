//
//  CaptureController.m
//  Capture
//
//  Created by Eric Baur on Sat Jul 03 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

#import "CaptureController.h"

static unsigned int queueID;

@implementation CaptureController

+ (void)initialize
{
	queueID = 0;
}

/*
- (void)dealloc
{
	[captureTask terminate];
	[super dealloc];
}
*/

- (id)init
{
	self = [super init];
	
	if (self) {
		conversations = [[NSMutableDictionary dictionary] retain];

		tableArray = [[NSArray alloc] init];
		conversationArray = [[NSArray alloc] init];
		
		packetArray = [[NSMutableArray alloc] init];

		updateNeeded = NO;
		dataQueued = NO;
		
		maxIdle = 30;
		removeIdle = NO;
		maxHide = 10;
		hideIdle = NO;
		interface = [[[Capture interfaces] objectAtIndex:0] retain];
		promiscuous = YES;
		requireSyn = NO;
		capturesData = YES;
		filter = [[NSString alloc] init];
		updateInterval = 100;
		showProcessing = NO;
		readFilename = [[NSString alloc] init];
		saveFilename = [[NSString alloc] init];

		saveAll = YES;
		
		searchString = nil;
		searchCategory = CCIntelligentSearchTag;

		captureQueueIdentifier = [[NSString stringWithFormat:@"queueServer-%d", queueID++] retain];
		INFO(NSLog(@"create captureQueue thread with ident: %@",captureQueueIdentifier));
		[NSThread
			detachNewThreadSelector:@selector(queueThreadWithSettings:)
			toTarget:[CaptureQueue class]
			withObject:[NSDictionary dictionaryWithObjectsAndKeys:
				self,					@"CaptureController",
				captureQueueIdentifier,	@"QueueIdentifier",
				nil
			]
		];
		
		captureToolIdentifier = [[NSString stringWithFormat:@"captureTool-%d", queueID++] retain];
		captureObject = [[Capture alloc]
			initWithServerIdentifier:captureToolIdentifier
			clientIdentifier:captureQueueIdentifier
		];
	}
	
	return self;
}

- (void)setUpdateInterval:(int)newUpdateInterval
{
	updateInterval = newUpdateInterval;
	if (updateTimer)
		[self startTimer];
}

- (void)startTimer
{
	ENTRY(NSLog( @"start time with interval: %d", updateInterval ));
	[updateTimer invalidate];
	[updateTimer release];
	updateTimer = [[NSTimer
		scheduledTimerWithTimeInterval:(updateInterval/1000.0)
		target:self
		selector:@selector(flushData:)
		userInfo:nil
		repeats:YES] retain
	];
}

- (void)setPacketQueueAndLock:(NSDictionary *)aDictionary
{
	packetAdditions = [[aDictionary objectForKey:@"additions"] retain];
	packetLock = [[aDictionary objectForKey:@"lock"] retain];
}

- (void)setReadFilename:(NSString *)newFilename
{
	[readFilename release];
	readFilename = newFilename;
	[readFilename retain];
}

- (void)setFollowsInserts:(BOOL)followInserts
{
	[conversationController setSelectsInsertedObjects:followInserts];
}

- (BOOL)followsInserts
{
	return [conversationController selectsInsertedObjects];
}

- (void)setHideIdle:(BOOL)newSetting
{
	if ( hideIdle && !newSetting ) {
		resetHidden = YES;
	}
	hideIdle = newSetting;
}

- (void)setFilter:(NSString *)newFilter;
{
	[filter release];
	filter = newFilter;
	[filter retain];
}

- (void)setTables:(NSArray *)newTables
{
	[tableArray release];
	tableArray = newTables;
	[tableArray retain];
}

- (CCSearchCategory)searchCategory
{
	return searchCategory;
}

- (void)setSearchCategory:(CCSearchCategory)newSearchCategory
{
	searchCategory = newSearchCategory;
}

- (IBAction)flushData:(id)sender
{
	VERBOSE(fprintf(stderr,"."));
	if (!packetLock)
		return;

	if ([captureQueueProxy updateNeeded]) {
		if ([captureQueueProxy dataQueued]) {
			[packetLock lock];
			[self addConversations:packetAdditions];
			[captureQueueProxy retreivedAdditions];
			[packetLock unlock];
		} else {
			NSEnumerator *en = [tableArray objectEnumerator];
			NSTableView *tempTable;
			while ( tempTable = [en nextObject] ) {
				[tempTable reloadData];
			};
		}
	}
	[self processRemovals];
}

- (void)addConversations:(NSArray *)newAdditions
{
	NSArray *tempArray = [conversationArray arrayByAddingObjectsFromArray:newAdditions];

	[conversationController addObjects:newAdditions];
	[conversationArray release];
	conversationArray = tempArray;
	[conversationArray retain];
}

- (void)processRemovals
{
	if (resetHidden) {
		[conversationController removeObjectsAtArrangedObjectIndexes:[NSIndexSet
			indexSetWithIndexesInRange:NSMakeRange(0,[[conversationController arrangedObjects] count])]
		];
		[conversationController addObjects:conversationArray];
		resetHidden = NO;
	}
	
	if (removeIdle) {
		double currentTimestamp = [[NSDate date] timeIntervalSince1970];
		NSMutableArray *removals = [NSMutableArray array];
		NSEnumerator *en = [[conversationController arrangedObjects] objectEnumerator];
		Conversation *tempConv;
		while (tempConv = [en nextObject]) {
			if ([tempConv lastTimestamp] < (currentTimestamp-maxIdle)) {
				[removals addObject:tempConv];
			}
		}
		if ([removals count]>0) {
			[conversationController removeObjects:removals];
			NSMutableArray *tempArray = [conversationArray mutableCopy];
			[tempArray removeObjectsInArray: removals];
			[conversationArray release];
			conversationArray = [tempArray retain];
		}
	}
	if (hideIdle) {
		double currentTimestamp = [[NSDate date] timeIntervalSince1970];
		NSMutableArray *hides = [NSMutableArray array];
		NSEnumerator *en = [[conversationController arrangedObjects] objectEnumerator];
		Conversation *tempConv;
		while (tempConv = [en nextObject]) {
			if ([tempConv lastTimestamp] < (currentTimestamp-maxHide)) {
				[hides addObject:tempConv];
			}
		}
		if ([hides count]>0) {
			[conversationController removeObjects:hides];
		}
	}
	if (searchString) {
		[conversationController removeObjects:[self
				processSearchOnArray:[conversationController arrangedObjects]
				keepMatches:NO
			]
		];
	}
}

- (NSArray *)processSearchOnArray:(NSArray *)targetArray keepMatches:(BOOL)keepMatches
{
	ENTRY(NSLog( @"[CaptureController processSearchOnArray:]" ));
	NSMutableArray *keeps = [NSMutableArray arrayWithArray:targetArray];
	NSEnumerator *en = [targetArray objectEnumerator];
	Conversation *tempConv;
	BOOL found;
	while (tempConv = [en nextObject]) {
		found = NO;
		if ( searchCategory==CCClientIPSearchTag || searchCategory==CCHostIPSearchTag ) {
			if ([[tempConv source] rangeOfString:searchString options:NSCaseInsensitiveSearch].location!=NSNotFound) {
				found = YES;
			}
		}
		if ( searchCategory==CCServerIPSearchTag || searchCategory==CCHostIPSearchTag ) {
			if ([[tempConv destination] rangeOfString:searchString options:NSCaseInsensitiveSearch].location!=NSNotFound) {
				found = YES;
			}
		}
		if ( searchCategory==CCClientPortSearchTag || searchCategory==CCPortSearchTag ) {
			if ([tempConv sourcePort] == [searchString intValue]) {
				found = YES;
			}
		}
		if ( searchCategory==CCServerPortSearchTag || searchCategory==CCPortSearchTag ) {
			if ([tempConv destinationPort] == [searchString intValue]) {
				found = YES;
			}
		}
		if ( searchCategory==CCClientPayloadSearchTag || searchCategory==CCPayloadSearchTag ) {
			NSString *tempString = [[[NSString alloc]
				initWithData:[tempConv clientPayload] encoding:NSASCIIStringEncoding ]
					autorelease];
			if ([tempString rangeOfString:searchString options:NSCaseInsensitiveSearch].location!=NSNotFound) {
				found = YES;
			}
		}
		if ( searchCategory==CCServerPayloadSearchTag || searchCategory==CCPayloadSearchTag ) {
			NSString *tempString = [[[NSString alloc]
				initWithData:[tempConv serverPayload] encoding:NSASCIIStringEncoding ]
					autorelease];
			if ([tempString rangeOfString:searchString options:NSCaseInsensitiveSearch].location!=NSNotFound) {
				found = YES;
			}
		}
		if (!found && keepMatches) {
			[keeps removeObject:tempConv];
		} else if (found && !keepMatches) {
			[keeps removeObject:tempConv];
		}
	}
	return [keeps copy];
}

- (void)searchForString:(NSString *)newSearchString
{
	ENTRY(NSLog( @"[CaptureController searchForString:\"%@\"]", newSearchString ));
	
	[searchString release];
	if ([newSearchString isEqualToString:@""])
		searchString = nil;
	else
		searchString = [newSearchString retain];
	
	if (searchString==nil) {
		resetHidden = YES;
		[self processRemovals];
		return;
	}
	
	//if (searchCategory==CCIntelligentSearchTag) {
		//need to guess at what we're searching for...
		
	//	[self processRemovals];
	//	searchCategory=CCIntelligentSearchTag;
	//} else {
		[self processRemovals];
	//}
}

- (IBAction)startCapture:(id)sender
{
	ENTRY(NSLog(@"[CaptureController startCapture:]"));
	NSString *filterString;
	if ( ! filter || [filter isEqual:@""] )
		filterString = @"tcp";
	else
		filterString = [NSString stringWithFormat:@"tcp and (%@)",filter];

	[Conversation setRequiresSyn:requireSyn];
	[Conversation setCapturesData:capturesData];

	[captureObject setDevice:interface];
	[captureObject setCaptureFilter:filterString];
	[captureObject setPromiscuous:promiscuous];
	
	if ( ![readFilename isEqual:@""] )
		[captureObject setReadFile:readFilename];
	
	[captureObject startCapture];
	
	if ([captureObject isActive]) {
		[sender setTitle:@"Stop Capture"];
		[sender setAction:@selector(stopCapture:)];
		captureButton = sender;
		[captureButton retain];
		[self startTimer];
	}
	
	[captureQueueProxy release];
	captureQueueProxy = [[NSConnection
			rootProxyForConnectionWithRegisteredName:captureQueueIdentifier host:nil
		] retain
	];
	[captureQueueProxy setProtocolForProxy:@protocol(PacketHandler)];
}

- (IBAction)stopCapture:(id)sender
{
	ENTRY(NSLog(@"[CaptureController stopCapture:]"));
	[captureButton setTitle:@"Start Capture"];
	[captureButton setAction:@selector(startCapture:)];

	if ([captureObject isActive]) {
		[captureObject stopCapture];
	}
	
	[updateTimer invalidate];
	[updateTimer release];
	updateTimer = nil;
	[self flushData:self];
}

- (void)setArrayController:(NSArrayController *)controller
{
	[conversationController release];
	conversationController = controller;
	[conversationController retain];
}

@end
