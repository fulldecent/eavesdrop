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

- (void)setData:(NSArray *)data;
- (NSArray *)data;

- (void)setCurrentIdentifier:(NSString *)newIdent;
- (NSString *)currentIdentifier;
- (NSArray *)dataIdentifiers;
- (void)setIndependentIdentifier:(NSString *)newIdentifier;
- (NSString *)independentIdentifier;
- (void)removeIndependent;
- (BOOL)hasIndependent;
- (double)valueAtPoint:(double)inputValue forKey:(NSString *)outputKey;
- (double)valueAtIndex:(double)inputIndex forKey:(NSString *)outputKey;

- (void)addViewIdentifier:(NSString *)newViewIdent;
- (void)addViewIdentifiersFromArray:(NSArray *)newViewIdents;
- (void)setViewIdentifiers:(NSArray *)newViewIdents;
- (void)removeViewIdentifier:(NSString *)oldViewIdent;
- (void)removeAllViews;
- (void)resetViews;
- (NSArray *)viewIdentifiers;

- (void)setNumberOfBins:(int)newNumberOfBins;
- (int)numberOfBins;
- (void)setBinSize:(double)newBinSize;
- (double)binSize;

- (NSArray *)histogramForCurrentIdentifier;
- (NSArray *)dataPointsForCurrentIdentifier;
- (NSArray *)dataPointsForCurrentIdentifierStartingAt:(double)startingNum endingAt:(double)endingNum;
- (NSArray *)dataPointsForCurrentIdentifierWithKey:(NSString *)forKey equalTo:(int)keyValue;

- (void)sort;

- (int)count;
- (double)total;
- (double)arithmeticMean;
- (double)populationStdDev;
- (double)sampleStdDev;
- (double)mode;
- (double)domainMinimum;
- (double)globalMinimum;
- (double)minimum;
- (double)firstQuartile;
- (double)median;
- (double)thirdQuartile;
- (double)maximum;
- (double)globalMaximum;
- (double)domainMaximum;

- (void)findGlobalMinAndMax;

@end
