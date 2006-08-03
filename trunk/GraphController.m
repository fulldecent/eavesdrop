//
//  GraphController.m
//  Eavesdrop
//
//  Created by Eric Baur on 12/18/04.
//  Copyright 2004 Eric Shore Baur. All rights reserved.
//

#import "GraphController.h"

@implementation GraphController

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
		independentTag = GCPacketIDTag;
		dependentTag = GCDeltaTag;
		chartDisplayTag = GCDeltaTag;
		minY=minX=0;
		maxY=maxX=1;
	}
	return self;
}

- (void)awakeFromNib
{
	[self bind:@"conversation" toObject:conversationController
		withKeyPath:@"selection.myself" options:nil ];
}

#pragma mark accessor methods

- (void)setConversation:(Conversation *)newConversation
{
	//NSLog( @"[GraphController setConversation:]" );
	[conversation release];
	conversation = [newConversation retain];
	
	if (conversation!=nil) {
		[self refreshGraph];
		[self refreshPieChart];
	}

}

- (void)setIndependentTag:(GCVariableType)newTag
{
	ENTRY(NSLog( @"changing independent tag from %d to %d", independentTag, newTag ));
	independentTag = newTag;
	[self refreshGraph];
}

- (void)setDependentTag:(GCVariableType)newTag
{
	ENTRY(NSLog( @"changing dependent tag from %d to %d", dependentTag, newTag ));
	dependentTag = newTag;
	[self refreshGraph];
}

- (void)setChartDisplayTag:(GCVariableType)newTag
{
	ENTRY(NSLog( @"changing chart display tag from %d to %d", chartDisplayTag, newTag ));
	chartDisplayTag = newTag;
	[self refreshPieChart];
}

- (void)setSourceTag:(int)newTag
{
	ENTRY(NSLog( @"changing source tag from %d to %d", sourceTag, newTag ));
	sourceTag = newTag;
	[self refreshGraph];
}

- (void)setGraphType:(GCGraphType)newType
{
	ENTRY(NSLog( @"changing graph type from %d to %d", graphType, newType ));
	graphType = newType;
	[self refreshGraph];
}

- (NSString *)identifierForTag:(GCVariableType)tag
{
	switch (tag) {
		case GCPacketIDTag:		return GCPacketIDIdentifier;		break;
		case GCPacketNumberTag:	return GCPacketNumberIdentifier;	break;
		case GCTimeTag:			return GCTimeIdentifier;			break;
		case GCTotalSizeTag:	return GCTotalSizeIdentifier;		break;
		case GCPayloadLengthTag:return GCPayloadLengthIdentifier;	break;
		case GCWindowTag:		return GCWindowIdentifier;			break;
		case GCDeltaTag:		return GCDeltaIdentifier;			break;
		default:				return nil;
	}
}

- (NSString *)stringForTag:(GCVariableType)tag
{
	switch (tag) {
		case GCPacketIDTag:		return GCPacketIDString;		break;
		case GCPacketNumberTag:	return GCPacketNumberString;	break;
		case GCTimeTag:			return GCTimeString;			break;
		case GCTotalSizeTag:	return GCTotalSizeString;		break;
		case GCPayloadLengthTag:return GCPayloadLengthString;	break;
		case GCWindowTag:		return GCWindowString;			break;
		case GCDeltaTag:		return GCDeltaString;			break;
		default:				return nil;
	}
}

- (void)refreshGraph
{
	ENTRY(NSLog( @"[GraphController refresh]" ));
	[dataSet release];
	[dataSet2 release];
	
	switch( sourceTag )  {
		case GCAllPacketsTag:
			INFO(NSLog( @"gathering data for all packets" ));
			dataSet = [conversation
				dataSetWithKeys:[NSArray
					arrayWithObject:[self identifierForTag:dependentTag] ]
				independent:[self identifierForTag:independentTag]
				forHost:nil
			];
			dataSet2 = nil;
			break;
		case GCClientOnlyTag:
			ENTRY(NSLog( @"gathering data for client" ));
			dataSet = [conversation
				dataSetWithKeys:[NSArray
					arrayWithObject:[self identifierForTag:dependentTag] ]
				independent:[self identifierForTag:independentTag]
				forHost:[conversation source]
			];
			dataSet2 = nil;
			break;
		case GCServerOnlyTag:
			ENTRY(NSLog( @"gathering data for server" ));
			dataSet = [conversation
				dataSetWithKeys:[NSArray
					arrayWithObject:[self identifierForTag:dependentTag] ]
				independent:[self identifierForTag:independentTag]
				forHost:[conversation destination]
			];
			dataSet2 = nil;
			break;
		case GCBothHostsTag:
			ENTRY(NSLog( @"gathering data for both hosts" ));
			if (graphType==GCBarGraphType) {
				dataSet = [conversation
					dataSetWithKeys:[NSArray
						arrayWithObjects:[self identifierForTag:dependentTag],@"source",nil ]
					independent:[self identifierForTag:independentTag]
					forHost:nil
				];
				dataSet2 = nil;
			} else {
				dataSet = [conversation
					dataSetWithKeys:[NSArray
						arrayWithObject:[self identifierForTag:dependentTag] ]
					independent:[self identifierForTag:independentTag]
					forHost:[conversation source]
				];
				dataSet2 = [conversation
					dataSetWithKeys:[NSArray
						arrayWithObject:[self identifierForTag:dependentTag] ]
					independent:[self identifierForTag:independentTag]
					forHost:[conversation destination]
				];
			}
			break;
		case GCAllwFlagsTag:
			ENTRY(NSLog( @"gathering data for all packets with tags" ));
			dataSet = [conversation
				dataSetWithKeys:[NSArray arrayWithObjects:
					[self identifierForTag:dependentTag], @"flagNums", nil
				]
				independent:[self identifierForTag:independentTag]
				forHost:nil
			];
			dataSet2 = nil;
			break;
		default:
			NSLog( @"GraphController: no valid source tag set!  No refresh will be performed" );
			dataSet = nil;
			dataSet2 = nil;
			return;
	}
	if ([dataSet count])
		[dataSet retain];
	else
		dataSet = nil;
		
	if ([dataSet2 count])
		[dataSet2 retain];
	else
		dataSet2 = nil;
		
	minX = 0;
	minY = 0;
	
	if ([dataSet maximum]<[dataSet2 maximum])
		maxY = [dataSet2 maximum] * 1.1;
	else
		maxY = [dataSet maximum] * 1.1;
		
	if ([dataSet domainMaximum]<[dataSet2 domainMaximum])
		maxX = [dataSet2 domainMaximum];
	else
		maxX = [dataSet domainMaximum];
		
	INFO(NSLog( @"\n X range: %f -> %f\n Y range: %f -> %f\n", minX, maxX, minY, maxY ));

	[parentGraphView setLabel:[self stringForTag:dependentTag] forAxis:kSM2DGraph_Axis_Y_Left];
	[parentGraphView setLabel:[self stringForTag:independentTag] forAxis:kSM2DGraph_Axis_X];
	
	[parentGraphView reloadData];
	[parentGraphView reloadAttributes];
}

- (void)refreshPieChart
{
	NSEnumerator *en;
	NSDictionary *tempDict;
	NSString *client, *server;
	double clientDelta = 0;
	double serverDelta = 0;
	
	[pieChartArray release];
	switch (chartDisplayTag) {
		case GCTotalSizeTag:
			pieChartArray = [NSArray arrayWithObjects:
				[conversation valueForKey:@"sbytes"],
				[conversation valueForKey:@"dbytes"],
				nil
			];
			break;
		case GCPayloadLengthTag:
			pieChartArray = [NSArray arrayWithObjects:
				[NSNumber numberWithInt:[[conversation clientPayload] length] ],
				[NSNumber numberWithInt:[[conversation serverPayload] length] ],
				nil
			];
			break;
		case GCDeltaTag:
			en = [[conversation payloadArrayBySource] objectEnumerator];
			client = [conversation source];
			server = [conversation destination];
			while (tempDict=[en nextObject]) {
				if ([[tempDict objectForKey:@"source"] isEqualToString:client])
					clientDelta += [[tempDict objectForKey:@"timeDelta"] doubleValue];
				else if ([[tempDict objectForKey:@"source"] isEqualToString:server])
					serverDelta += [[tempDict objectForKey:@"timeDelta"] doubleValue];
			}
			pieChartArray = [NSArray arrayWithObjects:
				[NSNumber numberWithDouble:clientDelta],
				[NSNumber numberWithDouble:serverDelta],
				nil
			];
			break;
		default:
			pieChartArray = nil;
			break;
	}

	[pieChartArray retain];

	[parentPieChartView reloadData];
	[parentPieChartView reloadAttributes];
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
		case GCAllwFlagsTag:
			return 9;
			break;
		default:
			NSLog( @"GraphController: no valid source tag set!" );
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
	} else if ( sourceTag==GCAllwFlagsTag ) {
		switch (inLineIndex) {
			case 0:		graphColor = [NSColor greenColor];		break;
			case 1:		graphColor = [NSColor yellowColor];		break;
			case 2:		graphColor = [NSColor brownColor];		break;
			case 3:		graphColor = [NSColor blueColor];		break;
			case 4:		graphColor = [NSColor blackColor];		break;
			case 5:		graphColor = [NSColor blackColor];		break;
			case 6:		graphColor = [NSColor magentaColor];	break;
			case 7:		graphColor = [NSColor redColor];		break;
			default:	graphColor = [NSColor grayColor];
		}
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
	ENTRY(NSLog( @"[GraphController twoDGraphView:dataForLineIndex:]" ));
	if ( sourceTag!=GCAllwFlagsTag && inLineIndex==0 ) {
		if (dataSet) {
			return [dataSet dataPointsForCurrentIdentifier];
		} else {
			return nil;
		}
	} else if ( sourceTag!=GCAllwFlagsTag && inLineIndex==1 ) {
		if (dataSet2) {
			return [dataSet2 dataPointsForCurrentIdentifier];
		} else {
			return nil;
		}
	} else if ( sourceTag==GCAllwFlagsTag ) {
		if (dataSet) {
			return [dataSet dataPointsForCurrentIdentifierWithKey:@"flagNums" equalTo:inLineIndex];
		} else {
			return nil;
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
	if ( sourceTag==GCAllwFlagsTag ) {
		//do nothing, it should be the right color already... maybe
	} else {
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
}

#pragma mark SMPieChartView datasource methods

- (unsigned int)numberOfSlicesInPieChartView:(SMPieChartView *)inPieChartView
{
	return 2;
}

- (NSDictionary *)pieChartView:(SMPieChartView *)inPieChartView attributesForSliceIndex:(unsigned int)inSliceIndex
{
	if (inSliceIndex==0) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSColor redColor], NSBackgroundColorAttributeName,
			[NSColor clearColor], NSForegroundColorAttributeName,
			nil
		];
	} else if (inSliceIndex==1) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSColor blueColor], NSBackgroundColorAttributeName,
			[NSColor clearColor], NSForegroundColorAttributeName,
			nil
		];
	} else {
		return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSColor blackColor], NSBackgroundColorAttributeName,
			[NSColor clearColor], NSForegroundColorAttributeName,
			nil
		];
	}
}
- (NSArray *)pieChartViewArrayOfSliceData:(SMPieChartView *)inPieChartView
{
	return pieChartArray;
}


@end
