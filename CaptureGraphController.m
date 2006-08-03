//
//  CaptureGraphController.m
//  Eavesdrop
//
//  Created by Eric Baur on 12/27/04.
//  Copyright 2004 Eric Shore Baur. All rights reserved.
//

#import "CaptureGraphController.h"

@implementation CaptureGraphController

+ (void)initialize	//may not need this one...
{
//	[self setKeys:[NSArray arrayWithObjects:@"setContent", @"dataSet", @"selection", nil]
//		triggerChangeNotificationsForDependentKey:@"content"];
}

- (id)init
{
	//NSLog( @"[GraphController init]" );
	self = [super init];
	if (self) {
		independentTag = GCConversationIDTag;
		dependentTag = GCMaxWaitTimeTag;
		graphType = GCScatterPlotType;
		sourceTag = GCBothHostsTag;
		minY=minX=0;
		maxY=maxX=1;
		
		dataSet = [[DataSet alloc] init];
		dataSet2 = [[DataSet alloc] init];
		
		scopeTag = allPacketsScopeTag;
		//scopeSelectedPackets = 0;
	}
	return self;
}

- (void)awakeFromNib
{
//	[self bind:@"conversationArray" toObject:conversationController
//		withKeyPath:@"contentArray" options:nil ];
}

#pragma mark accessor methods
/*
- (void)setConversationArray:(NSArray *)newArray
{
	NSLog( @"[CaptureGraphController setConversationArray]" );
	[conversationArray release];
	conversationArray = [newArray retain];
	
	[self refreshGraph];
}
*/
- (void)setIndependentTag:(GCVariableType)newTag
{
	ENTRY(NSLog( @"changing independent tag from %d to %d", independentTag, newTag ));
	independentTag = newTag;
	[self refreshGraph:self];
}

- (void)setDependentTag:(GCVariableType)newTag
{
	ENTRY(NSLog( @"changing dependent tag from %d to %d", dependentTag, newTag ));
	dependentTag = newTag;
	[self refreshGraph:self];
}

- (void)setSourceTag:(int)newTag
{
	ENTRY(NSLog( @"changing source tag from %d to %d", sourceTag, newTag ));
	sourceTag = newTag;
	[self refreshGraph:self];
}

- (void)setGraphType:(GCGraphType)newType
{
	ENTRY(NSLog( @"changing graph type from %d to %d", graphType, newType ));
	graphType = newType;
	[self refreshGraph:self];
}

- (int)scopeTag
{
	return scopeTag;
}

- (void)setScopeAllPackets:(int)newScope
{
	NSLog( @"setScopeAllPackets: %d", newScope );
	scopeTag = newScope;
}

#pragma mark constants / conversion methods

- (NSString *)identifierForTag:(GCVariableType)tag
{
	switch (tag) {
		case GCPacketIDTag:				return GCPacketIDIdentifier;			break;
		case GCPacketNumberTag:			return GCPacketNumberIdentifier;		break;
		case GCTimeTag:					return GCTimeIdentifier;				break;
		case GCTotalSizeTag:			return GCTotalSizeIdentifier;			break;
		case GCPayloadLengthTag:		return GCPayloadLengthIdentifier;		break;
		case GCWindowTag:				return GCWindowIdentifier;				break;
		case GCDeltaTag:				return GCDeltaIdentifier;				break;
		case GCPacketsTag:				return GCPacketsIdentifier;				break;
		case GCTimeLengthTag:			return GCTimeLengthIdentifier;			break;
		case GCConversationIDTag:		return GCConversationIDIdentifier;		break;
		case GCMaxWaitTimeTag:			return GCMaxWaitTimeIdentifier;			break;
		case GCConnectWaitTimeTag:		return GCConnectWaitTimeIdentifier;		break;
		case GCServerMaxWaitTimeTag:	return GCServerMaxWaitTimeIdentifier;	break;
		case GCClientMaxWaitTimeTag:	return GCClientMaxWaitTimeIdentifier;	break;
		case GCServerPortTag:			return GCServerPortIdentifier;			break;
		case GCClientPortTag:			return GCClientPortIdentifier;			break;
		case GCBytesPerSecondTag:		return GCBytesPerSecondIdentifier;		break;
		case GCAllDeltasTag:			return GCAllDeltasIdentifier;			break;
		case GCServerDeltasTag:			return GCServerDeltasIdentifier;		break;
		case GCClientDeltasTag:			return GCClientDeltasIdentifier;		break;
		default:						return nil;
	}
}

- (NSString *)stringForTag:(GCVariableType)tag
{
	switch (tag) {
		case GCPacketIDTag:				return GCPacketIDString;			break;
		case GCPacketNumberTag:			return GCPacketNumberString;		break;
		case GCTimeTag:					return GCTimeString;				break;
		case GCTotalSizeTag:			return GCTotalSizeString;			break;
		case GCPayloadLengthTag:		return GCPayloadLengthString;		break;
		case GCWindowTag:				return GCWindowString;				break;
		case GCDeltaTag:				return GCDeltaString;				break;
		case GCPacketsTag:				return GCPacketsString;				break;
		case GCTimeLengthTag:			return GCTimeLengthString;			break;
		case GCConversationIDTag:		return GCConversationIDString;		break;
		case GCMaxWaitTimeTag:			return GCMaxWaitTimeString;			break;
		case GCConnectWaitTimeTag:		return GCConnectWaitTimeString;		break;
		case GCServerMaxWaitTimeTag:	return GCServerMaxWaitTimeString;	break;
		case GCClientMaxWaitTimeTag:	return GCClientMaxWaitTimeString;	break;
		case GCServerPortTag:			return GCServerPortString;			break;
		case GCClientPortTag:			return GCClientPortString;			break;
		case GCBytesPerSecondTag:		return GCBytesPerSecondString;		break;
		case GCAllDeltasTag:			return GCAllDeltasString;			break;
		case GCServerDeltasTag:			return GCServerDeltasString;		break;
		case GCClientDeltasTag:			return GCClientDeltasString;		break;
		default:						return nil;
	}
}

#pragma mark action methods

- (IBAction)refreshGraph:(id)sender
{
	ENTRY(NSLog( @"[CaptureGraphController refresh]" ));
	[refreshProgress setDoubleValue:0];
	[refreshProgress setMaxValue:[[conversationController arrangedObjects] count] ];
	[refreshProgress setHidden:NO];
	[refreshProgress displayIfNeeded];
	
	NSString *dependentKey = [self identifierForTag:dependentTag];
	NSString *independentKey = [self identifierForTag:independentTag];
	
	NSEnumerator *en;
	if ( scopeTag == allPacketsScopeTag )
		en = [[conversationController arrangedObjects] objectEnumerator];
	else
		en = [[conversationController selectedObjects] objectEnumerator];
		
	Conversation *tempConv;
	NSMutableArray *tempArray1 = [NSMutableArray array];
	NSMutableArray *tempArray2 = [NSMutableArray array];

	[refreshProgress setIndeterminate:NO];
	while (tempConv=[en nextObject]) {
		[refreshProgress incrementBy:1];
		[refreshProgress displayIfNeeded];
		switch( sourceTag )  {
			case GCAllPacketsTag:
				ENTRY(NSLog( @"gathering data for all packets" ));
				[tempArray1 addObjectsFromArray:
							[ [tempConv
								dataSetWithKeys:[NSArray arrayWithObject:dependentKey]
								independent:independentKey
								forHost:nil]
							data ]
				];
				tempArray2 = nil;
				break;
			case GCClientOnlyTag:
				ENTRY(NSLog( @"gathering data for client" ));
				[tempArray1 addObjectsFromArray:
							[ [tempConv
								dataSetWithKeys:[NSArray arrayWithObject:dependentKey]
								independent:independentKey
								forHost:[tempConv source] ]
							data ]
				];
				tempArray2 = nil;
				break;
			case GCServerOnlyTag:
				ENTRY(NSLog( @"gathering data for server" ));
				[tempArray1 addObjectsFromArray:
							[ [tempConv
								dataSetWithKeys:[NSArray arrayWithObject:dependentKey]
								independent:independentKey
								forHost:[tempConv destination] ]
							data ]
				];
				tempArray2 = nil;
				break;
			case GCBothHostsTag:
				ENTRY(NSLog( @"gathering data for both hosts" ));
				if (graphType==GCBarGraphType) {
					[tempArray1 addObjectsFromArray:
						[ [tempConv
							dataSetWithKeys:[NSArray arrayWithObject:dependentKey]
							independent:independentKey
							forHost:nil]
						data ]
					];
					tempArray2 = nil;
				} else {
					[tempArray1 addObjectsFromArray:
						[ [tempConv
							dataSetWithKeys:[NSArray arrayWithObject:dependentKey]
							independent:independentKey
							forHost:[tempConv source] ]
						data ]
					];
					[tempArray2 addObjectsFromArray:
						[ [tempConv
							dataSetWithKeys:[NSArray arrayWithObject:dependentKey]
							independent:independentKey
							forHost:[tempConv destination] ]
						data ]
					];
				}
				break;
			default:
				NSLog( @"GraphController: no valid source tag set!  No refresh will be performed" );
				tempArray1 = nil;
				tempArray2 = nil;
				return;
		}
	}
	
	[refreshProgress setIndeterminate:YES];
	[refreshProgress startAnimation:self];
	[refreshProgress displayIfNeeded];

	if ([tempArray1 count]) {
		ENTRY(NSLog( @"setting dataSet with %d objects", [tempArray1 count] ));
		[dataSet setData:[tempArray1 copy] ];
	} else {
		[dataSet setData:nil];
	}

	if ([tempArray2 count]) {
		ENTRY(NSLog( @"setting dataSet2 with %d objects", [tempArray2 count] ));
		[dataSet2 setData:[tempArray2 copy] ];
	} else {
		[dataSet2 setData:nil];
	}
	
	[dataSet setIndependentIdentifier:independentKey ];
	[dataSet setCurrentIdentifier:dependentKey ];
	
	[dataSet2 setIndependentIdentifier:independentKey ];
	[dataSet2 setCurrentIdentifier:dependentKey ];
	
	if (independentTag==GCTimeTag)
		minX = [dataSet domainMinimum];
	else
		minX = 0;

	if (independentTag==GCTimeTag)
		minY = [dataSet minimum] * 0.9;
	else
		minY = 0;
	
	maxX = [dataSet domainMaximum];
	maxY = [dataSet maximum] * 1.1;
		
	INFO(NSLog( @"\n X range: %f -> %f\n Y range: %f -> %f\n", minX, maxX, minY, maxY ));

	[parentGraphView setLabel:[self stringForTag:dependentTag] forAxis:kSM2DGraph_Axis_Y_Left];
	[parentGraphView setLabel:[self stringForTag:independentTag] forAxis:kSM2DGraph_Axis_X];
	
	[parentGraphView reloadData];
	[parentGraphView reloadAttributes];

	[refreshProgress setHidden:YES];
	[refreshProgress stopAnimation:self];
	[refreshProgress displayIfNeeded];
}

#pragma mark action methods

- (IBAction)swapVariables:(id)sender
{
	GCVariableType tempTag;
	tempTag = independentTag;
	independentTag = dependentTag;
	dependentTag = tempTag;
	
	[self refreshGraph:self];
}

- (IBAction)saveData:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setRequiredFileType:@"txt"];
	
	int runResult = [savePanel runModal];
	
	if (runResult == NSOKButton) {
		if (![[[dataSet description] dataUsingEncoding:NSASCIIStringEncoding] writeToFile:[savePanel filename] atomically:YES])
			NSBeep();
	}
}

#pragma mark SM2DGraphView datasource methods

- (unsigned int)numberOfLinesInTwoDGraphView:(SM2DGraphView *)inGraphView
{
	switch( sourceTag )  {
		case GCBothHostsTag:
			if (graphType==GCBarGraphType)
				return 1;
			else
				return 2;
			break;
		case GCAllPacketsTag:
		case GCClientOnlyTag:
		case GCServerOnlyTag:
			return 1;
			break;
		default:
			NSLog( @"CaptureGraphController: no valid source tag set!" );
			return 0;
	}
}

- (NSDictionary *)twoDGraphView:(SM2DGraphView *)inGraphView attributesForLineIndex:(unsigned int)inLineIndex
{
	ENTRY(NSLog( @"getting COLOR" ));
	NSColor *graphColor;
	if ( inLineIndex==0 && (sourceTag==GCClientOnlyTag || sourceTag==GCBothHostsTag) ) {
		graphColor = [NSColor redColor];
	} else if (inLineIndex==1 || sourceTag==GCServerOnlyTag ) {
		graphColor = [NSColor blueColor];
	} else {
		graphColor = [NSColor blackColor];
	}
	
	if (graphType==GCBarGraphType) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
			graphColor,	NSForegroundColorAttributeName,
			@"on",		SM2DGraphBarStyleAttributeName,
			nil
		];
	} else if (graphType==GCScatterPlotType) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
			graphColor,
				NSForegroundColorAttributeName,
			[NSNumber numberWithInt:kSM2DGraph_Symbol_FilledCircle],
				SM2DGraphLineSymbolAttributeName,
			[ NSNumber numberWithInt:kSM2DGraph_Width_None ],
				SM2DGraphLineWidthAttributeName,
			nil
		];
	} else {
		return [NSDictionary dictionaryWithObjectsAndKeys:
			graphColor,
				NSForegroundColorAttributeName,
			[NSNumber numberWithInt:kSM2DGraph_Symbol_FilledCircle],
				SM2DGraphLineSymbolAttributeName,
			nil
		];
	}
}

- (NSArray *)twoDGraphView:(SM2DGraphView *)inGraphView dataForLineIndex:(unsigned int)inLineIndex
{
	ENTRY(NSLog( @"[CaptureGraphController twoDGraphView:dataForLineIndex:]" ));
	if (inLineIndex==0) {
		if ([[dataSet data] count]) {
			return [dataSet dataPointsForCurrentIdentifier];
		}
	} else if (inLineIndex==1) {
		if ([[dataSet2 data] count]) {
			return [dataSet2 dataPointsForCurrentIdentifier];
		}
	}
	return nil;
}

- (double)twoDGraphView:(SM2DGraphView *)inGraphView maximumValueForLineIndex:(unsigned int)inLineIndex
            forAxis:(SM2DGraphAxisEnum)inAxis
{
	if (inAxis==kSM2DGraph_Axis_Y_Left || inAxis==kSM2DGraph_Axis_Y_Right) {
		return maxY;
	} else if (inAxis==kSM2DGraph_Axis_X) {
		return maxX;
	} else {
		return 1;
	}
}

- (double)twoDGraphView:(SM2DGraphView *)inGraphView minimumValueForLineIndex:(unsigned int)inLineIndex
            forAxis:(SM2DGraphAxisEnum)inAxis
{
	if (inAxis==kSM2DGraph_Axis_Y_Left || inAxis==kSM2DGraph_Axis_Y_Right) {
		return minY;
	} else if (inAxis==kSM2DGraph_Axis_X) {
		return minX;
	} else {
		return 0;
	}
}

#pragma mark SM2DGraphView delegate methods

- (void)twoDGraphView:(SM2DGraphView *)inGraphView willDisplayBarIndex:(unsigned int)inBarIndex
	forLineIndex:(unsigned int)inLineIndex withAttributes:(NSMutableDictionary *)attr
{
	int source = [dataSet valueAtIndex:inBarIndex forKey:@"source" ];
	INFO(NSLog( @"source = %d", source ));
	if (graphType==GCBarGraphType) {
		if (source==-1)
			[attr setObject:[NSColor blueColor] forKey:NSForegroundColorAttributeName];
		else if (source==1)
			[attr setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
		else
			[attr setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];		
	}
}

@end
