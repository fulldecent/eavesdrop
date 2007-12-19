//
//  CaptureDocument.m
//  Eavesdrop
//
//  Created by Eric Baur on 5/16/06.
//  Copyright Eric Shore Baur 2006 . All rights reserved.
//

#import "CaptureDocument.h"

@implementation CaptureDocument

#pragma mark -
#pragma mark Setup methods

+ (void)initialize
{
	ENTRY( @"initialize" );
}

- (id)init 
{
	ENTRY( @"init" );
    self = [super init];
    if (self) {
		identifier = [[self description] retain];
		queueIdentifier = [NSString stringWithFormat:@"%@ (queue)", identifier];

		DEBUG( @"detach PacketQueue thread" );
		[NSThread
			detachNewThreadSelector:@selector(startCollectorWithIdentifier:)
			toTarget:[PacketQueue class]
			withObject:queueIdentifier
		];
		isRefreshing = NO;

		packetList = [[NSMutableArray alloc] init];
		leftoverPacketList = [[NSMutableArray alloc] init];

		appDelegate = [[NSApp delegate] retain];
		[self setAggregate:@"Aggregate"];
		
		
		libraryArray = [[NSMutableArray array] retain];
		
		[libraryArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:YES],	@"isSourceGroup",
			@"Library",						@"name",
			[NSArray array],				@"children",
			nil ]
		];
		
		NSDictionary *pluginDict = [Plugin registeredAggregators];
		NSMutableArray *tempArray = [NSMutableArray array];
		for ( NSString *key in pluginDict ) {
			[tempArray addObject:[NSDictionary dictionaryWithObject:[[pluginDict objectForKey:key] valueForKey:@"name"] forKey:@"name"] ];
		}
		[libraryArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:YES],	@"isSourceGroup",
			@"Aggregators",					@"name",
			tempArray,						@"children",
			nil ]
		];
		
		pluginDict  = [Plugin registeredDissectors];
		tempArray = [NSMutableArray array];
		for ( NSString *key in pluginDict ) {
			NSString *tempString = [[pluginDict objectForKey:key] valueForKey:@"protocol"];
			if ( [tempString isEqualToString:@""] )
				[tempArray addObject:[NSDictionary dictionaryWithObject:@"All" forKey:@"name"] ];
			else
				[tempArray addObject:[NSDictionary dictionaryWithObject:tempString forKey:@"name"] ];
		}
		[libraryArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:YES],	@"isSourceGroup",
			@"Dissectors",					@"name",
			tempArray,						@"children",
			nil ]
		];
		
		pluginDict  = [Plugin registeredDecoders];
		tempArray = [NSMutableArray array];
		for ( NSString *key in pluginDict ) {
			[tempArray addObject:[NSDictionary dictionaryWithObject:[[pluginDict objectForKey:key] valueForKey:@"name"] forKey:@"name"] ];
		}
		[libraryArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:YES],	@"isSourceGroup",
			@"Decoders",					@"name",
			tempArray,						@"children",
			nil ]
		];

    }
	EXIT( @"done with init" );
	
	return self;
}

- (void)awakeFromNib
{
	[packetOutlineView setIntercellSpacing:NSMakeSize(0,1) ];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(updateDetailsFromMainOutlineView)
		name:@"NSOutlineViewSelectionDidChangeNotification"
		object:packetOutlineView
	];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(updateDetailsFromLeftoverOutlineView)
		name:@"NSOutlineViewSelectionDidChangeNotification"
		object:leftoverOutlineView
	];
	
	//this is here because I can't get the settings to stick in IB
	[packetInfoDrawer setContentSize:NSMakeSize(300,400)];
	
	[packetOutlineView setDoubleAction:@selector(makeKeyAndOrderFront:)];
	[packetOutlineView setTarget:packetDetailWindow];
	[leftoverOutlineView setDoubleAction:@selector(makeKeyAndOrderFront:)];
	[leftoverOutlineView setTarget:packetDetailWindow];
	
	[packetOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:EDPacketsPboardType, EDPacketSourcePboardType, nil]];
    [packetOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    [packetOutlineView setDraggingSourceOperationMask:NSDragOperationAll_Obsolete forLocal:NO];
}

- (NSString *)windowNibName 
{
    return @"CaptureDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{
    [super windowControllerDidLoadNib:windowController];
    
	//TODO: fix remote captures (maybe not here)
	[self connectToCaptureServer:self];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	ENTRY2( @"readFromURL:%@ ofType:%@ error:(out)", [absoluteURL description], typeName );
	[self setReadFile:[absoluteURL path] ];
	BOOL readFile = [[[[NSUserDefaultsController sharedUserDefaultsController]
		values] valueForKey:@"readFileOnOpen"] boolValue];
	if (readFile)
		[self startCapture:self];
		
	return YES;
}

- (void)saveToURL:(NSURL *)absoluteURL
	ofType:(NSString *)typeName
	forSaveOperation:(NSSaveOperationType)saveOperation
	delegate:(id)delegate
	didSaveSelector:(SEL)didSaveSelector
	contextInfo:(void *)contextInfo
{
	ENTRY( @"saveToURL:ofType:forSaveOperation:delegate:didSaveSelector:contextInfo:" );
	[self setSaveFile:[absoluteURL path] ];
	[self startSave:self];
}

- (void)setDefaults
{
	NSDictionary *defaultsDict = [[NSUserDefaultsController sharedUserDefaultsController] values];
	
	[self setInterface:[defaultsDict valueForKey:@"interface"] ];
	[self setPromiscuous:[[defaultsDict valueForKey:@"promiscuous"] boolValue] ];
	[self setTableRefresh:[[defaultsDict valueForKey:@"tableRefresh"] intValue] ];
}

- (PacketQueue *)packetQueue
{
	if (!packetQueue) {	
		packetQueue = [PacketQueue collectorWithIdentifier:queueIdentifier];
		if (packetQueue) {
			DEBUG1( @"got packetQueue proxy: %@", [packetQueue description] );
		} else {
			ERROR( @"failed to get packetQueue proxy!" );
		}
	}
	return packetQueue;
}

#pragma mark -
#pragma mark Actions

- (IBAction)connectToCaptureServer:(id)sender
{
	[self willChangeValueForKey:@"serverProxy"];
	ENTRY( @"connectToCaptureServer" );

	NSString *tempHost = nil;
	NSString *tempIdentifier = @"CaptureServer";
	if (CDRemoteCaptureType==captureType) {
		DEBUG2( @"looking for '%@' at: %@", remoteHostIdentifier, remoteHostAddress );
		tempHost = remoteHostAddress;
		tempIdentifier = remoteHostIdentifier;
	}
	
	int tries = 0;
	for ( tries=0; tries <= 3 && !serverProxy; tries++ ) {
		serverProxy = [[DOHelpers
			getProxyWithName:tempIdentifier
			protocol:@protocol(CaptureServer)
			host:tempHost
		] retain];
		if (serverProxy) {
			DEBUG1(@"got serverProxy: %@",[serverProxy description]);
			[serverProxy addCaptureForClient:queueIdentifier ];
		} else {
			WARNING(@"failed to get serverProxy" );
		}
	}
	[self didChangeValueForKey:@"serverProxy"];
	
	[self setDefaults];
}

- (IBAction)startSave:(id)sender
{
	ENTRY( @"startSave:" );
	if ( [self isActive] ) {
		ERROR( @"cannot start save, a capture is active" );
		return;
	}
	
	NSMutableArray *allItems = [NSMutableArray array];
	NSEnumerator *en = [packetList objectEnumerator];
	id tempItem;
	while ( tempItem=[en nextObject] ) {
		if ( [tempItem isKindOfClass:[Aggregate class]] ) {
			[allItems addObjectsFromArray:[tempItem valueForKey:@"allPackets"] ];
		} else if ( [tempItem isKindOfClass:[Dissector class]] ) {
			[allItems addObject:tempItem];
		} else {
			ERROR( @"item in list is neither an Aggregate or a Dissector" );
		}
	}
	
	if (fileSaver) {
		[fileSaver savePackets:allItems];
	}
}

- (IBAction)startCapture:(id)sender
{
	if ( [self isActive] ) {
		ERROR( @"Cannot start, a capture is already active" );
		return;
	}
	
	[self willChangeValueForKey:@"isActive"];
	if (fileCaptureThread) {
		[NSThread detachNewThreadSelector:@selector(startCapture) toTarget:fileCaptureThread withObject:nil];
	} else if (serverProxy) {
		[serverProxy startCaptureForClient:queueIdentifier ];
	}
	[self setTableRefresh:refreshMilliseconds];
	[self didChangeValueForKey:@"isActive"];
}

- (IBAction)stopCapture:(id)sender
{
	if (fileCaptureThread)
		[fileCaptureThread stopCapture];
		
	if (serverProxy)
		[serverProxy stopCaptureForClient:queueIdentifier];
	
	[self refreshData:self];
	
	[PacketQueue stopCollectorWithIdentifier:queueIdentifier];
}

- (IBAction)refreshData:(id)sender
{
	if (isRefreshing) {
		DEBUG( @"already refreshing - returning" );
		return;
	}
	isRefreshing = YES;

	NSArray *tempArray = nil;
	NSArray *leftoverArray = nil;
	@try {
		if (aggregateUsed) {
			tempArray = [[self packetQueue] flushNewAggregateArray];
			leftoverArray = [[self packetQueue] flushNewLeftoverArray];
		} else {
			tempArray = [[self packetQueue] flushNewPacketArray];
		}
	}
	@catch (NSException *e) {
		ERROR1( @"exception in refreshing data: %@", [e reason] );
		[serverProxy release];
		serverProxy = nil;
		[tableTimer invalidate];
		[PacketQueue stopCollectorWithIdentifier:queueIdentifier];
	}
	
	if ( [tempArray count] ) {
		[packetList addObjectsFromArray:tempArray];
		[packetOutlineView reloadData];
	}
	if ( [leftoverArray count] ) {
		[leftoverPacketList addObjectsFromArray:leftoverArray];
		[leftoverOutlineView reloadData];
	}
	
/*
	if ( [leftoverPacketList count] ) {
		[[packetSplitView subviewWithIdentifier:@"leftovers"] expand];
	} else {
		[[packetSplitView subviewWithIdentifier:@"leftovers"] collapse];
	}
*/
	
	isRefreshing = NO;
}

- (IBAction)killServer:(id)sender
{
	[self willChangeValueForKey:@"serverProxy"];
	[serverProxy killServer];
	[self didChangeValueForKey:@"serverProxy"];
}

- (IBAction)showSettings:(id)sender
{
	[NSApp
		beginSheet:settingsWindow
		modalForWindow:documentWindow
		modalDelegate:self
		didEndSelector:@selector(settingsSheetDidEnd:returnCode:contextInfo:)
		contextInfo:nil
	];
}

- (IBAction)saveSettings:(id)sender
{
	[NSApp endSheet:settingsWindow];
}

- (IBAction)launchServer:(id)sender
{
	[appDelegate performSelector:@selector(launchCaptureServer:) withObject:self];	
	[self connectToCaptureServer:self];
}

- (IBAction)chooseFile:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel
		beginSheetForDirectory:nil
		file:nil
		types:[NSArray arrayWithObject:@"cap"]
		modalForWindow:settingsWindow
		modalDelegate:self
		didEndSelector:@selector(chooseFilePanelDidEnd:returnCode:contextInfo:)
		contextInfo:nil
	];
}

- (IBAction)applyAggregates:(id)sender
{
	[self willChangeValueForKey:@"aggregate"];
	[self willChangeValueForKey:@"aggregateArrayController"];
	
	[packetList removeAllObjects];
	[leftoverPacketList removeAllObjects];
	
	[[self packetQueue] resetNewPacketIndex];

	NSArray *tempArray = [aggregateArrayController arrangedObjects];
	if ( !tempArray || [tempArray count]==0 ) {
		aggregateUsed = NO;
	} else {
		aggregateUsed = YES;
	}
	[[self packetQueue] setAggregateClassArray:tempArray ];
	
	[self didChangeValueForKey:@"aggregate"];
	[self didChangeValueForKey:@"aggregateArrayController"];
}

- (void)updateDetailsFromMainOutlineView
{
	if ( [packetOutlineView numberOfSelectedRows] ) {
		[leftoverOutlineView deselectAll:self];
		[self updateDetailsFromOutlineView:packetOutlineView];
	}
}

- (void)updateDetailsFromLeftoverOutlineView
{
	if ( [leftoverOutlineView numberOfSelectedRows] ) {
		[packetOutlineView deselectAll:self];
		[self updateDetailsFromOutlineView:leftoverOutlineView];	
	}
}

- (void)updateDetailsFromOutlineView:(NSOutlineView *)sourceOutlineView
{
	NSIndexSet *indexSet = [sourceOutlineView selectedRowIndexes];
	DEBUG2( @"updateDetailsFromOutlineView: %@ (with indexSet: %@)", [sourceOutlineView description], [indexSet description] );
	
	[self willChangeValueForKey:@"selectedPacket"];
	[self willChangeValueForKey:@"packetDetailsArray"];
	[self willChangeValueForKey:@"packetDetailsTreeArray"];
	[packetDetailsArray release];
	packetDetailsArray = nil;
	[packetDetailsTreeArray release];
	packetDetailsTreeArray = nil;
	if ( [indexSet count]==1 ) {
		selectedPacket = [sourceOutlineView itemAtRow:[indexSet firstIndex]];
		packetDetailsArray = [selectedPacket allDetailsArray];
		packetDetailsTreeArray = [selectedPacket detailsTreeArray];
	}
	[self didChangeValueForKey:@"packetDetailsTreeArray"];
	[self didChangeValueForKey:@"packetDetailsArray"];
	[self didChangeValueForKey:@"selectedPacket"];
	//INFO1( @"packetDetailsTreeArray:\n%@", [packetDetailsTreeArray description] );
}

#pragma mark -
#pragma mark Accessors

- (void)setCaptureType:(CDCaptureType)newType
{
	ENTRY( @"setCaptureType:" );

	[self willChangeValueForKey:@"captureType"];	
	[self willChangeValueForKey:@"serverProxy"];
	[self willChangeValueForKey:@"fileCaptureThread"];
	[self willChangeValueForKey:@"readFile"];
	if ( CDLocalCaptureType==captureType && CDFileCaptureType==newType ) {
		[serverProxy release];
		serverProxy = nil;
	} else if ( CDLocalCaptureType==captureType && CDRemoteCaptureType==newType ) {
		//do something to move from a local server to remote server
	} else if ( CDFileCaptureType==captureType && CDLocalCaptureType==newType ) {
		[fileCaptureThread release];
		fileCaptureThread = nil;
		[self connectToCaptureServer:self];
	} else if ( CDFileCaptureType==captureType && CDRemoteCaptureType==newType ) {
		[fileCaptureThread release];
		fileCaptureThread = nil;
		//connect to remote server somehow
	} else if ( CDRemoteCaptureType==captureType && CDLocalCaptureType==newType ) {
		//do something
		[self connectToCaptureServer:self];
	} else if ( CDRemoteCaptureType==captureType && CDFileCaptureType==newType ) {
		//do something
	}
	
	captureType = newType;
	
	[self didChangeValueForKey:@"captureType"];
	[self didChangeValueForKey:@"serverProxy"];
	[self didChangeValueForKey:@"fileCaptureThread"];
	[self didChangeValueForKey:@"readFile"];
}

- (int)tableRefresh
{
	return refreshMilliseconds;
}

- (void)setTableRefresh:(int)newRefresh
{
	[tableTimer invalidate];
	[tableTimer release];
	tableTimer = nil;
	
	if ( newRefresh ) {
		refreshMilliseconds = newRefresh;
		tableTimer = [[NSTimer
			scheduledTimerWithTimeInterval:( refreshMilliseconds / 1000.0 )
			target:self
			selector:@selector(refreshData:)
			userInfo:nil
			repeats:YES
		] retain];
	} else {
		DEBUG( @"table refresh timer turned off" );
	}
}

- (NSString *)aggregate
{
	return [[self packetQueue] aggregateClassName];
}

- (void)setAggregate:(NSString *)newAggregate
{
	ENTRY1( @"setAggregate: %@", newAggregate );

	[self willChangeValueForKey:@"aggregate"];
	[self willChangeValueForKey:@"aggregateArrayController"];

	[packetList removeAllObjects];
	[leftoverPacketList removeAllObjects];

	[packetOutlineView reloadData];
	[leftoverOutlineView reloadData];
	
	[[self packetQueue] resetNewPacketIndex];

	aggregateUsed = ! [newAggregate isEqualToString:[Aggregate className]];
	[[self packetQueue] setAggregateClassName:newAggregate];
	
	[self didChangeValueForKey:@"aggregate"];
	[self didChangeValueForKey:@"aggregateArrayController"];
	
	[self refreshData:self];
}
/*
- (NSString *)subAggregate
{
	return [[self packetQueue] aggregateClassName];
}

- (void)setSubAggregate:(NSString *)newAggregate
{
	ENTRY1( @"setAggregate: %@", newAggregate );

	[packetList removeAllObjects];
	[leftoverPacketList removeAllObjects];

	[packetOutlineView reloadData];
	[leftoverOutlineView reloadData];
	
	[[self packetQueue] resetNewPacketIndex];

	aggregateUsed = ! [newAggregate isEqualToString:[Aggregate className]];
	[[self packetQueue] setAggregateClassName:newAggregate];
	
	[self refreshData:self];
}
*/

#pragma mark -
#pragma mark Capture Properties

- (NSMutableArray *)interfaces
{
	//this isn't doing what I want it to...
	// ... it should be able to bind to the combo box
	NSArray *serverInterfaces;
	NSMutableArray *tempArray = [NSMutableArray array];
	if (serverProxy)
		serverInterfaces = [serverProxy interfaces];
	else
		serverInterfaces = [NSArray array];
		
	NSEnumerator *en = [serverInterfaces objectEnumerator];
	NSString *tempString;
	while ( tempString = [en nextObject] ) {
		[tempArray addObject:
			[NSMutableDictionary dictionaryWithObject:tempString forKey:@"name"]
		];
	}
	return tempArray;
}

- (NSString *)saveFile
{
	if (fileSaver)
		return [fileSaver saveFile];
		
	return nil;
}

- (void)setSaveFile:(NSString *)saveFile
{
	[self willChangeValueForKey:@"saveFile"];
	[self willChangeValueForKey:@"fileSaver"];
	
	if (!saveFile) {
		[fileSaver release];
		fileSaver = nil;
	} else if (!fileSaver) {
		fileSaver = [[CaptureThread alloc] init];
	}
	[fileSaver setSaveFile:saveFile];
	
	[self didChangeValueForKey:@"saveFile"];
	[self didChangeValueForKey:@"fileSaver"];
}

- (NSString *)readFile
{
	if (fileCaptureThread)
		return [fileCaptureThread readFile];
		
	if (serverProxy)
		return [serverProxy readFileForClient:queueIdentifier];
		
	return nil;
}

- (void)setReadFile:(NSString *)readFile
{
	//this is the only property method that doesn't set
	//both the local file thread and the server proxy
	[self willChangeValueForKey:@"fileCaptureThread"];
	[self willChangeValueForKey:@"readFile"];
	[self willChangeValueForKey:@"captureType"];
	if (readFile) {
		captureType = CDFileCaptureType;
		if (!fileCaptureThread) {
			fileCaptureThread = [[CaptureThread alloc] init];
		}
		[fileCaptureThread setClient:queueIdentifier];
		[fileCaptureThread setReadFile:readFile];
	} else {
		captureType = CDLocalCaptureType;
		[fileCaptureThread release];
		fileCaptureThread = nil;
	}
	[self didChangeValueForKey:@"captureType"];
	[self didChangeValueForKey:@"readFile"];
	[self didChangeValueForKey:@"fileCaptureThread"];
}

- (NSString *)captureFilter
{
	if (fileCaptureThread)
		return [fileCaptureThread captureFilter];
		
	if (serverProxy)
		return [serverProxy captureFilterForClient:queueIdentifier ];

	return @"";
}

- (void)setCaptureFilter:(NSString *)filterString
{
	if (fileCaptureThread)
		[fileCaptureThread setCaptureFilter:filterString];
		
	if (serverProxy)
		[serverProxy setCaptureFilter:filterString forClient:queueIdentifier ];
}

- (NSString *)interface
{
	if (fileCaptureThread)
		return [fileCaptureThread interface];
		
	if (serverProxy)
		return [serverProxy interfaceForClient:queueIdentifier ];

	return @"";
}

- (void)setInterface:(NSString *)newInterface
{
	ENTRY1( @"setInterface:%@", newInterface );
	if (fileCaptureThread)
		[fileCaptureThread setInterface:newInterface];
		
	if (serverProxy)
		[serverProxy setInterface:newInterface forClient:queueIdentifier ];
}

- (BOOL)promiscuous
{
	if (fileCaptureThread)
		return [fileCaptureThread promiscuous];
		
	if (serverProxy)
		return [serverProxy promiscuousForClient:queueIdentifier ];

	return YES;
}

- (void)setPromiscuous:(BOOL)promiscuousMode
{
	if (fileCaptureThread)
		[fileCaptureThread setPromiscuous:promiscuousMode];
		
	if (serverProxy)
		[serverProxy setPromiscuous:promiscuousMode forClient:queueIdentifier ];
}

- (BOOL)capturesPayload
{
	if (fileCaptureThread)
		return [fileCaptureThread capturesPayload];
		
	if (serverProxy)
		return [serverProxy capturesPayloadForClient:queueIdentifier ];

	return YES;
}

- (void)setCapturesPayload:(BOOL)shouldCapture
{
	if (fileCaptureThread)
		[fileCaptureThread setCapturesPayload:shouldCapture];
		
	if (serverProxy)
		[serverProxy setCapturesPayload:shouldCapture forClient:queueIdentifier ];
}

- (BOOL)isActive
{
	if (fileCaptureThread)
		return [fileCaptureThread isActive];
		
	if (serverProxy)
		return [serverProxy isActiveForClient:queueIdentifier ];

	return NO;
}

#pragma mark -
#pragma mark Observers

- (void)settingsSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	[sheet orderOut:self];
}

- (void)chooseFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	if ( NSOKButton == returnCode ) {
		[self setReadFile:[sheet filename] ];
	}
	[sheet orderOut:self];
}

#pragma mark -
#pragma mark Window Delegate methods

- (void)windowWillClose:(NSNotification *)aNotification
{
	ENTRY( @"windowWillClose:" );
	[tableTimer invalidate];
	[self stopCapture:self];
}

#pragma mark -
#pragma mark NSOutlineView Datasource methods

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return ( 
		[item respondsToSelector:@selector(packetArray)]
		//&& [[item performSelector:@selector(packetArray)] count]
	);
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	//if we're not at the root, we can call the same child methods
	if (item)
		return [[item performSelector:@selector(packetArray)] count];

	if ( outlineView==packetOutlineView ) {
		return [packetList count];
	} else if ( outlineView==leftoverOutlineView ) {
		return [leftoverPacketList count];
	} else {
		ERROR( @"delegate method called w/no known parent outlineView" );
		return 0;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	//if we're not at the root, we can call the same child method
	if (item)
		return [[item performSelector:@selector(packetArray)] objectAtIndex:index];

	//at the root, we need to pick which array we use as the base
	if ( outlineView==packetOutlineView ) {
		return [packetList objectAtIndex:index];
	} else if ( outlineView==leftoverOutlineView ) {
		return [leftoverPacketList objectAtIndex:index];
	} else {
		ERROR( @"delegate method called w/no known parent outlineView" );
		return nil;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	//we're assuming any outline view that calls this is configured the same
	if (item) {
		return [item valueForKey:[tableColumn identifier] ];	
	} else {
		return nil;
	}
}

#pragma mark -
#pragma mark NSOutlineView Delegate methods

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	[cell setDrawsBackground:YES];
	[cell setBackgroundColor:[[Dissector pluginDefaultsForClass:[item class]] valueForKey:@"backgroundColor"] ];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	//this is used to draw the arrow button
	//[cell setBackgroundColor:[[Dissector pluginDefaultsForClass:[item class]] valueForKey:@"backgroundColor"] ];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
	ENTRY( @"outlineView:writeItems:toPasteboard:" );

	NSMutableArray *allItems = [NSMutableArray array];
	NSEnumerator *en = [items objectEnumerator];
	id tempItem;
	while ( tempItem=[en nextObject] ) {
		if ( [tempItem isKindOfClass:[Aggregate class]] ) {
			[allItems addObjectsFromArray:[tempItem valueForKey:@"allPackets"] ];
		} else if ( [tempItem isKindOfClass:[Dissector class]] ) {
			[allItems addObject:tempItem];
		} else {
			ERROR( @"dragged items is neither an Aggregate or a Dissector" );
		}
	}
	
	NSMutableArray *simplifiedItems = [NSMutableArray array];
	en = [allItems objectEnumerator];
	while ( tempItem=[en nextObject] ) {
		[simplifiedItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[tempItem valueForKey:@"packetHeaderData"], @"packetHeaderData",
				[tempItem valueForKey:@"packetPayloadData"], @"packetPayloadData",
				nil
			]
		];
	}

	//prepare 
	[pboard declareTypes:[NSArray arrayWithObjects:
			EDPacketsPboardType,
			EDPacketSourcePboardType,
			NSStringPboardType,
			NSFilesPromisePboardType,
			nil
		] owner:self
	];

	[pboard setData:[NSArchiver archivedDataWithRootObject:simplifiedItems] forType:EDPacketsPboardType];
	[pboard setData:[NSArchiver archivedDataWithRootObject:identifier] forType:EDPacketSourcePboardType];
	//support text-mode drag and drop (not working!)
	if ( ![pboard setString:[allItems description] forType:NSStringPboardType] ) {
		ERROR( @"failed to write string to pasteboard" );
	}
    //support file creation
	[pboard setPropertyList:[NSArray arrayWithObjects:@"cap", nil] forType:NSFilesPromisePboardType];
	
	return YES;
}
 
 - (unsigned int)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
	//make sure it wasn't dropped on ourselves, there might be a better way
	NSPasteboard *pboard = [info draggingPasteboard];		
	if ( [[NSUnarchiver unarchiveObjectWithData:[pboard dataForType:EDPacketSourcePboardType]] isEqualToString:identifier] ) {
		return NO;
	}

	//only allow drop on whole view
	[outlineView setDropItem:nil dropChildIndex:NSOutlineViewDropOnItemIndex];

	return NSDragOperationCopy;
 }

- (BOOL)outlineView:(NSOutlineView*)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
	ENTRY( @"outlineView:acceptDrop:item:" );
	NSPasteboard *pboard = [info draggingPasteboard];
	
	NSData *data = [pboard dataForType:EDPacketsPboardType];
	NSArray *items = [NSUnarchiver unarchiveObjectWithData:data];
	
	NSEnumerator *en = [items objectEnumerator];
	id tempItem;
	while ( tempItem=[en nextObject] ) {
		[[self packetQueue]
			addPacket:[tempItem valueForKey:@"packetPayloadData"]
			withHeader:[tempItem valueForKey:@"packetHeaderData"]
		];
	}

	return YES;
}

// Create a fileHandle for writing to a new file located in the directory specified by 'dirpath'.
//If the file basename.extension already exists at that location, then append "-N"
//(where N is a whole number starting with 1) until a unique basename-N.extension file is found.
//On return oFilename contains the name of the newly created file referenced by the returned NSFileHandle.
NSFileHandle *NewFileHandleForWritingFile(NSString *dirpath, NSString *basename, NSString *extension, NSString **oFilename)
{
    NSString *filename = nil;
    BOOL done = NO;
    int fdForWriting = -1, uniqueNum = 0;
    while (!done) {
        filename = [NSString stringWithFormat:@"%@%@.%@", basename, (uniqueNum ? [NSString stringWithFormat:@"-%d", uniqueNum] : @""), extension];
        fdForWriting = open([[NSString stringWithFormat:@"%@/%@", dirpath, filename] UTF8String], O_WRONLY | O_CREAT | O_EXCL, 0666);
        if (fdForWriting < 0 && errno == EEXIST) {
            // Try another name.
            uniqueNum++;
        } else {
            done = YES;
        }
    }

    NSFileHandle *fileHandle = nil;
    if (fdForWriting>0) {
        fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fdForWriting closeOnDealloc:YES];
    }
    
    if (oFilename) {
        *oFilename = (fileHandle ? filename : nil);
    }
    
    return fileHandle;
}

// We promised the files, so now lets make good on that promise!
- (NSArray *)outlineView:(NSTableView *)tv namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items
{	
	NSString *filename  = nil;
    NSMutableArray *filenames = [NSMutableArray array];
	NSFileHandle *fileHandle = NewFileHandleForWritingFile([dropDestination path], @"Packet Clipping", @"cap", &filename);
	if (fileHandle) {
		[self setSaveFile:filename];
		if (fileSaver) {
			//since we can save off things... go ahead and build the array of items
			NSMutableArray *allItems = [NSMutableArray array];
			NSEnumerator *en = [items objectEnumerator];
			id tempItem;
			while ( tempItem=[en nextObject] ) {
				if ( [tempItem isKindOfClass:[Aggregate class]] ) {
					[allItems addObjectsFromArray:[tempItem valueForKey:@"allPackets"] ];
				} else if ( [tempItem isKindOfClass:[Dissector class]] ) {
					[allItems addObject:tempItem];
				} else {
					ERROR( @"dropped item(s) are neither an Aggregate or a Dissector" );
				}
			}
			//this is not actually working... the file ends up being zero bytes...
			//... don't know why.
			[fileSaver savePackets:allItems];
			[filenames addObject:filename];
		}
	}
	DEBUG1( @"drop created file: %@", filename );
    return ([filenames count] ? filenames : nil);
}

#pragma mark -
#pragma mark NSTableView methods


@end


