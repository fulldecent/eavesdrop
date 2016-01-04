//
//  DataSet.h
//  GraphTest
//
//  Created by Eric Baur on 11/16/04.
//  Copyright 2004 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define DSGlobalIdentifier @"__DSGlobalIdentifier__"

@interface DataSet : NSObject {
	NSArray *data;						//an array of dictionaries
	NSString *currentIdentifier;		//the set that will return data for statistics
	NSArray *dataIdentifiers;			//all the available sets to use
	NSArray *viewIdentifiers;			//the sets that will be used for group statistics
	NSString *independentIdentifier;	//the set to be ignored by group statistics
	
	int numberOfBins;
	double binSize;
	
	NSMutableDictionary *results;
}

@property (NS_NONATOMIC_IOSONLY, copy) NSArray *data;

@property (NS_NONATOMIC_IOSONLY, copy) NSString *currentIdentifier;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *dataIdentifiers;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *independentIdentifier;
- (void)removeIndependent;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasIndependent;
- (double)valueAtPoint:(double)inputValue forKey:(NSString *)outputKey;
- (double)valueAtIndex:(double)inputIndex forKey:(NSString *)outputKey;

- (void)addViewIdentifier:(NSString *)newViewIdent;
- (void)addViewIdentifiersFromArray:(NSArray *)newViewIdents;
- (void)removeViewIdentifier:(NSString *)oldViewIdent;
- (void)removeAllViews;
- (void)resetViews;
@property (NS_NONATOMIC_IOSONLY, copy) NSArray *viewIdentifiers;

@property (NS_NONATOMIC_IOSONLY) int numberOfBins;
@property (NS_NONATOMIC_IOSONLY) double binSize;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *histogramForCurrentIdentifier;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *dataPointsForCurrentIdentifier;
- (NSArray *)dataPointsForCurrentIdentifierStartingAt:(double)startingNum endingAt:(double)endingNum;
- (NSArray *)dataPointsForCurrentIdentifierWithKey:(NSString *)forKey equalTo:(int)keyValue;

- (void)sort;

@property (NS_NONATOMIC_IOSONLY, readonly) int count;
@property (NS_NONATOMIC_IOSONLY, readonly) double total;
@property (NS_NONATOMIC_IOSONLY, readonly) double arithmeticMean;
@property (NS_NONATOMIC_IOSONLY, readonly) double populationStdDev;
@property (NS_NONATOMIC_IOSONLY, readonly) double sampleStdDev;
@property (NS_NONATOMIC_IOSONLY, readonly) double mode;
@property (NS_NONATOMIC_IOSONLY, readonly) double domainMinimum;
@property (NS_NONATOMIC_IOSONLY, readonly) double globalMinimum;
@property (NS_NONATOMIC_IOSONLY, readonly) double minimum;
@property (NS_NONATOMIC_IOSONLY, readonly) double firstQuartile;
@property (NS_NONATOMIC_IOSONLY, readonly) double median;
@property (NS_NONATOMIC_IOSONLY, readonly) double thirdQuartile;
@property (NS_NONATOMIC_IOSONLY, readonly) double maximum;
@property (NS_NONATOMIC_IOSONLY, readonly) double globalMaximum;
@property (NS_NONATOMIC_IOSONLY, readonly) double domainMaximum;

- (void)findGlobalMinAndMax;

@end
