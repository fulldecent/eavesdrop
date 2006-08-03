//
//  CaptureGraphController.h
//  Eavesdrop
//
//  Created by Eric Baur on 12/27/04.
//  Copyright 2004 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GC-Constants.h"

#import "DataSet.h"
#import "Conversation.h"

#import <SM2DGraphView/SM2DGraphView.h>

#define allPacketsScopeTag		0
#define selectedPacketsScopeTag	1

@interface CaptureGraphController : NSObject {
	DataSet *dataSet;
	DataSet *dataSet2;
	
	IBOutlet SM2DGraphView *parentGraphView;
	IBOutlet NSArrayController *conversationController;
	
	NSArray *conversationArray;
	
	GCVariableType independentTag, dependentTag;
	int sourceTag;
	int scopeTag;
	GCGraphType graphType;
	double minY, minX, maxY, maxX;
	NSArray *pieChartArray;
	
	IBOutlet NSProgressIndicator *refreshProgress;
}

- (void)setIndependentTag:(GCVariableType)newTag;
- (void)setDependentTag:(GCVariableType)newTag;
- (void)setSourceTag:(int)newTag;
- (int)scopeTag;
- (void)setScopeTag:(int)newScope;
- (NSString *)identifierForTag:(GCVariableType)tag;
- (NSString *)stringForTag:(GCVariableType)tag;

- (IBAction)refreshGraph:(id)sender;
- (IBAction)swapVariables:(id)sender;
- (IBAction)saveData:(id)sender;

- (unsigned int)numberOfLinesInTwoDGraphView:(SM2DGraphView *)inGraphView; 
- (NSDictionary *)twoDGraphView:(SM2DGraphView *)inGraphView attributesForLineIndex:(unsigned int)inLineIndex;
- (NSArray *)twoDGraphView:(SM2DGraphView *)inGraphView dataForLineIndex:(unsigned int)inLineIndex; 
- (double)twoDGraphView:(SM2DGraphView *)inGraphView maximumValueForLineIndex:(unsigned int)inLineIndex
            forAxis:(SM2DGraphAxisEnum)inAxis; 
- (double)twoDGraphView:(SM2DGraphView *)inGraphView minimumValueForLineIndex:(unsigned int)inLineIndex
            forAxis:(SM2DGraphAxisEnum)inAxis;

@end