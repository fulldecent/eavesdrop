//
//  GraphController.h
//  Eavesdrop
//
//  Created by Eric Baur on 12/18/04.
//  Copyright 2004 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DataSet.h"
#import "Conversation.h"

#import "SM2DGraphView.h"
#import "SMPieChartView.h"
//#import <SM2DGraphView/SM2DGraphView.h>
//#import <SM2DGraphView/SMPieChartView.h>

#import "GC-Constants.h"

@interface GraphController : NSObject {
	DataSet *dataSet;
	DataSet *dataSet2;
	Conversation *conversation;
	
	IBOutlet SM2DGraphView *parentGraphView;
	IBOutlet SMPieChartView *parentPieChartView;
	IBOutlet NSArrayController *conversationController;
	
	GCVariableType independentTag, dependentTag, chartDisplayTag;
	int sourceTag;
	GCGraphType graphType;
	double minY, minX, maxY, maxX;
	NSArray *pieChartArray;
}

- (void)setConversation:(Conversation *)newConversation;

- (void)setIndependentTag:(GCVariableType)newTag;
- (void)setDependentTag:(GCVariableType)newTag;
- (void)setChartDisplayTag:(GCVariableType)newTag;
- (void)setSourceTag:(int)newTag;
- (NSString *)identifierForTag:(GCVariableType)tag;
- (NSString *)stringForTag:(GCVariableType)tag;

- (void)refreshGraph;
- (void)refreshPieChart;

- (unsigned int)numberOfLinesInTwoDGraphView:(SM2DGraphView *)inGraphView; 
- (NSDictionary *)twoDGraphView:(SM2DGraphView *)inGraphView attributesForLineIndex:(unsigned int)inLineIndex;
- (NSArray *)twoDGraphView:(SM2DGraphView *)inGraphView dataForLineIndex:(unsigned int)inLineIndex; 
- (double)twoDGraphView:(SM2DGraphView *)inGraphView maximumValueForLineIndex:(unsigned int)inLineIndex
            forAxis:(SM2DGraphAxisEnum)inAxis; 
- (double)twoDGraphView:(SM2DGraphView *)inGraphView minimumValueForLineIndex:(unsigned int)inLineIndex
            forAxis:(SM2DGraphAxisEnum)inAxis;

- (unsigned int)numberOfSlicesInPieChartView:(SMPieChartView *)inPieChartView;
//- (double)pieChartView:(SMPieChartView *)inPieChartView dataForSliceIndex:(unsigned int)inSliceIndex;
- (NSArray *)pieChartViewArrayOfSliceData:(SMPieChartView *)inPieChartView;

@end