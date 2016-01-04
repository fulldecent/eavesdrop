//
//  DataSet.m
//  GraphTest
//
//  Created by Eric Baur on 11/16/04.
//  Copyright 2004 Eric Shore Baur. All rights reserved.
//

#import "DataSet.h"

@implementation DataSet

+ (void)initialize
{
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"numberOfBins"];
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"binSize"];
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"histogramForCurrentIdentifier"];

	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"dataPointsForCurrentIdentifier"];
		
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"count"];
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"total"];

	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"arithmeticMean"];
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"populationStdDev"];
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"sampleStdDev"];

	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"mode"];

	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"domainMinimum"];
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"globalMinimum"];
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"minimum"];
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"firstQuartile"];
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"median"];
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"thirdQuartile"];
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"maximum"];
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"globalMaximum"];
	[self setKeys:@[@"data"]
		triggerChangeNotificationsForDependentKey:@"domainMaximum"];
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		//currentIdentifier = @"";
		results = [[NSMutableDictionary alloc] init];
		
		//globalMin = globalMax = 0;
		binSize = 0;
		numberOfBins = 10;
	}
	return self;
}

- (NSString *)description
{
	NSEnumerator *en = [data objectEnumerator];
	NSDictionary *tempDict;
	NSMutableString *tempString = [NSMutableString string];
	
	while ( tempDict = [en nextObject] ) {
		[tempString appendFormat:@"%@\t%@\n",
			[tempDict[independentIdentifier] description],
			[tempDict[currentIdentifier] description]
		];
	}
	return [tempString copy];
}

#pragma mark accessor methods

- (void)setData:(NSArray *)newData
{
	//NSLog( @"[DataSet setData]" );
	if (newData.count==0)
		return;
		
	[data release];
	data = [newData retain];
	
	[dataIdentifiers release];
	dataIdentifiers = [[data[0] allKeys] retain];
	[self resetViews];
		
	[self setNumberOfBins:numberOfBins];
	
	[results release];
	results = [[NSMutableDictionary alloc] init];
	results[DSGlobalIdentifier] = [NSMutableDictionary dictionary];
	//[self sort];
}

- (NSArray *)data
{
	return data;
}

- (void)setCurrentIdentifier:(NSString *)newIdent
{
	//NSLog( @"[DataSet setCurrentIdentifier:@\"%@\"]", newIdent );
	[currentIdentifier release];
	currentIdentifier = [newIdent retain];
	
	if (!results[currentIdentifier] && currentIdentifier) {
		results[currentIdentifier] = [NSMutableDictionary dictionary];
	}
	//NSLog( @"results:\n%@", [results description] );
	
	//[self sort];
}

- (NSString *)currentIdentifier
{
	return currentIdentifier;
}

- (NSArray *)dataIdentifiers
{
	return dataIdentifiers;
}

- (void)setIndependentIdentifier:(NSString *)newIdentifier
{
	[independentIdentifier release];
	independentIdentifier = [newIdentifier retain];
}

- (NSString *)independentIdentifier
{
	return independentIdentifier;
}

- (void)removeIndependent
{
	[independentIdentifier release];
	independentIdentifier = nil;
}

- (BOOL)hasIndependent
{
	if (independentIdentifier)
		return YES;
	else
		return NO;
}

- (double)valueAtPoint:(double)inputValue forKey:(NSString *)outputKey
{
	NSLog( @"[DataSet valueAtPoint:forKey:] is not implemented yet" );
	return 0;
}

- (double)valueAtIndex:(double)inputIndex forKey:(NSString *)outputKey
{
	ENTRY(NSLog( @"[DataSet valueAtIndex:forKey:]" ));
	if (independentIdentifier==nil || [independentIdentifier isEqualToString:@""]) {
		NSLog( @"DataSet: no independent identifier set - returning bogus value" );
		return 0;
	}
		
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc]
		initWithKey:independentIdentifier ascending:YES] autorelease
	];
	NSArray *tempData = [data sortedArrayUsingDescriptors:@[sortDescriptor]
	];
	[data release];
	data = [tempData retain];
	
	return [data[(int)inputIndex][outputKey] doubleValue];
}

#pragma mark view options

- (void)addViewIdentifier:(NSString *)newViewIdent
{
	ENTRY(NSLog( @"[DataSet addViewIdentifier:%@ ]", newViewIdent ));
	NSMutableArray *tempArray = [viewIdentifiers mutableCopy];
	if (![newViewIdent isEqualToString:independentIdentifier])
		[tempArray addObject:newViewIdent];
	[viewIdentifiers release];
	viewIdentifiers = [[tempArray copy] retain];
}

- (void)addViewIdentifiersFromArray:(NSArray *)newViewIdents
{
	ENTRY(NSLog( @"[DataSet addViewIdentifiersFromArray:]" ));
	NSMutableArray *tempArray = [viewIdentifiers mutableCopy];
	[tempArray addObjectsFromArray:newViewIdents];
	[tempArray removeObject:independentIdentifier];	//this may not work (object, not string?)
	[viewIdentifiers release];
	viewIdentifiers = [[tempArray copy] retain];
}

- (void)setViewIdentifiers:(NSArray *)newViewIdents
{
	[self removeAllViews];
	[self addViewIdentifiersFromArray:newViewIdents];
}

- (void)removeViewIdentifier:(NSString *)oldViewIdent
{
	ENTRY(NSLog( @"[DataSet removeViewIdentifier:%@ ]", oldViewIdent ));
	NSMutableArray *tempArray = [viewIdentifiers mutableCopy];
	[tempArray removeObject:oldViewIdent];
	[viewIdentifiers release];
	viewIdentifiers = [[tempArray copy] retain];
}

- (void)removeAllViews
{
	ENTRY(NSLog( @"[DataSet removeAllViews]" ));
	[viewIdentifiers release];
	viewIdentifiers = [[NSArray alloc] init];
}

- (void)resetViews
{
	NSMutableArray *tempArray = [dataIdentifiers mutableCopy];
	[tempArray removeObject:independentIdentifier];
	[viewIdentifiers release];
	viewIdentifiers = [[tempArray copy] retain];
	ENTRY(NSLog( @"[DataSet resetViews]\n%@", [viewIdentifiers description] ));
}

- (NSArray *)viewIdentifiers
{
	return [viewIdentifiers copy];
}

#pragma mark histogram and graphing methods

- (void)setNumberOfBins:(int)newNumberOfBins
{
	ENTRY(NSLog( @"[DataSet setNumberOfBins:%d", newNumberOfBins ));
	numberOfBins = newNumberOfBins;
	binSize = ([self globalMaximum]-[self globalMinimum])/numberOfBins;
}

- (int)numberOfBins
{
	return numberOfBins;
}

- (void)setBinSize:(double)newBinSize
{
	ENTRY(NSLog( @"[DataSet setBinSize:%f]", newBinSize ));
	binSize = newBinSize;
	numberOfBins = ([self globalMaximum]-[self globalMinimum])/binSize + 1;	//do I need the +1?
}

- (double)binSize
{
	return binSize;
}

- (NSArray *)histogramForCurrentIdentifier
{
	ENTRY(NSLog( @"[DataSet historgramForCurrentIdentifier]" ));
	if ( binSize==0 || [currentIdentifier isEqualToString:@""]
		|| [currentIdentifier isEqualToString:independentIdentifier]) {
		return nil;
	}

	NSEnumerator *en = [data objectEnumerator];
	NSDictionary *tempDict;
	
	int binValues[ numberOfBins ];
	double check;
	int i;
	BOOL foundPlacement;
	double globalMin = [self globalMinimum];
	double globalMax = [self globalMaximum];
	
	INFO(NSLog( @"Globals: ( %f, %f )", globalMin, globalMax ));
	INFO(NSLog( @"Histogram using %d bins of size: %f", numberOfBins, binSize ));
	for(i=0; i<numberOfBins; i++)
		binValues[i] = 0;
	
	while (tempDict=[en nextObject]) {
		check =  [tempDict[currentIdentifier] doubleValue];
		foundPlacement = NO;
		for (i=0; i<numberOfBins; i++) {
			if ( check>=(globalMin+i*binSize) && check<(globalMin+(i+1)*binSize) ) {
				binValues[i]++;
				foundPlacement = YES;
			}
		}
		if (!foundPlacement && check==globalMax)	//might be a better way to do this...
			binValues[i]++;
		else if (!foundPlacement)
			NSLog( @"couldn't find place for: %f", check );
	}
	NSMutableArray *tempArray = [NSMutableArray array];
	for (i=0; i<numberOfBins; i++) {
		[tempArray addObject:@{@"bin": @(i),
				@"value": @(binValues[i]),
				@"min": @(globalMin+i*binSize),
				@"max": @(globalMin+(i+1)*binSize)}
		];
	}
	return [tempArray copy];
}

- (NSArray *)dataPointsForCurrentIdentifier
{
	return [self dataPointsForCurrentIdentifierStartingAt:0 endingAt:0];
}

- (NSArray *)dataPointsForCurrentIdentifierStartingAt:(double)startingNum endingAt:(double)endingNum
{
	if (independentIdentifier==nil || [independentIdentifier isEqualToString:@""])
		return nil;
		
	if (currentIdentifier==nil || [currentIdentifier isEqualToString:@""])
		return nil;

	NSSortDescriptor *independentSort = [[[NSSortDescriptor alloc]
		initWithKey:independentIdentifier ascending:YES] autorelease
	];
	NSSortDescriptor *currentSort = [[[NSSortDescriptor alloc]
		initWithKey:currentIdentifier ascending:YES] autorelease
	];

	NSArray *tempData = [data sortedArrayUsingDescriptors:@[independentSort, currentSort]
	];

	NSMutableArray *pointTable = [NSMutableArray array];
	
	NSEnumerator *en = [tempData objectEnumerator];
	NSDictionary *tempDict;
	double tempNum;
	while (tempDict=[en nextObject]) {
		if (startingNum==endingNum) {
			[pointTable addObject: NSStringFromPoint(
					NSMakePoint(
						[tempDict[independentIdentifier] doubleValue],
						[tempDict[currentIdentifier] doubleValue]
					)
				)
			];
		} else {
			tempNum = [tempDict[independentIdentifier] doubleValue];
			if ( tempNum >= startingNum && tempNum <= endingNum )
				[pointTable addObject: NSStringFromPoint(
						NSMakePoint(
							[tempDict[independentIdentifier] doubleValue],
							[tempDict[currentIdentifier] doubleValue]
						)
					)
				];
		}
	}
	//NSLog( @"pointTable:\n%@", [pointTable description] );
	return [pointTable copy];
}

- (NSArray *)dataPointsForCurrentIdentifierWithKey:(NSString *)forKey equalTo:(int)keyValue
{
	ENTRY(NSLog( @"[DataSet dataPointsForCurrentIdentifierWithKey:%@ equalTo:%d", forKey, keyValue ));
	if (independentIdentifier==nil || [independentIdentifier isEqualToString:@""])
		return nil;
		
	if (currentIdentifier==nil || [currentIdentifier isEqualToString:@""])
		return nil;

	NSSortDescriptor *independentSort = [[[NSSortDescriptor alloc]
		initWithKey:independentIdentifier ascending:YES] autorelease
	];
	NSSortDescriptor *currentSort = [[[NSSortDescriptor alloc]
		initWithKey:currentIdentifier ascending:YES] autorelease
	];

	NSArray *tempData = [data sortedArrayUsingDescriptors:@[independentSort, currentSort]
	];


	NSMutableArray *pointTable = [NSMutableArray array];
	
	INFO(NSLog( @"data description:\n%@", [tempData description] ));
	
	NSEnumerator *en = [tempData objectEnumerator];
	NSDictionary *tempDict;
	double tempNum;
	int checkNum;
	while (tempDict=[en nextObject]) {
		tempNum = [tempDict[independentIdentifier] doubleValue];
		checkNum = [tempDict[forKey] intValue];
		if ( checkNum==keyValue ) {
			[pointTable addObject: NSStringFromPoint(
					NSMakePoint(
						[tempDict[independentIdentifier] doubleValue],
						[tempDict[currentIdentifier] doubleValue]
					)
				)
			];
		}
	}
	ENTRY(NSLog( @" - returning %d records", [pointTable count] ));
	return [pointTable copy];
}

#pragma mark statistics methods

- (void)sort
{
	ENTRY(NSLog( @"[DataSet sort]" ));
	if (currentIdentifier==nil || [currentIdentifier isEqualToString:@""])
		return;
		
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc]
		initWithKey:currentIdentifier ascending:YES] autorelease
	];
	NSArray *tempData = [data sortedArrayUsingDescriptors:@[sortDescriptor]
	];
	[data release];
	data = [tempData retain];
}

- (int)count
{	//might not need the cached result here (unless we use it to return all at once)
	return data.count;
}

- (double)total
{
	if (results[currentIdentifier][@"total"])
		return [results[currentIdentifier][@"total"] doubleValue];
		
	ENTRY(NSLog( @"[DataSet total]" ));
	NSEnumerator *en = [data objectEnumerator];
	NSDictionary *tempDict;
	
	double total = 0;
	
	while (tempDict=[en nextObject]) {
		total += [tempDict[currentIdentifier] doubleValue];
	}
	
	results[currentIdentifier][@"total"] = @(total);
	return total;
}

- (double)arithmeticMean
{	//might not need to cached result here (unless we use it to return a large data set all at once)
	//NSLog( @"[DataSet arithmeticMean] = %f", [self total] / [data count] );
	return ( [self total] / data.count );
}

- (double)populationStdDev
{
	if (results[currentIdentifier][@"populationStdDev"])
		return [results[currentIdentifier][@"populationStdDev"] doubleValue];
		
	double avg = [self arithmeticMean  ];
	double total = 0;
	double x;
	
	NSEnumerator *en = [data objectEnumerator];
	NSDictionary *tempDict;
	
	while (tempDict=[en nextObject]) {
		x = [tempDict[currentIdentifier] doubleValue];
		total += (x-avg)*(x-avg);
	}
	double stddev = sqrt( total / data.count );
	results[currentIdentifier][@"populationStdDev"] = @(stddev);
	return stddev;
}

- (double)sampleStdDev
{
	if (results[currentIdentifier][@"sampleStdDev"])
		return [results[currentIdentifier][@"sampleStdDev"] doubleValue];
		
	double avg = [self arithmeticMean  ];
	double total = 0;
	double x;
	
	NSEnumerator *en = [data objectEnumerator];
	NSDictionary *tempDict;
	
	while (tempDict=[en nextObject]) {
		x = [tempDict[currentIdentifier] doubleValue];
		total += (x-avg)*(x-avg);
	}
	
	double stddev = sqrt( total / (data.count-1) );
	results[currentIdentifier][@"sampleStdDev"] = @(stddev);
	return stddev;
}

- (double)mode
{
	NSLog( @"[DataSet mode] : not implemented" );
	return 0;
}

- (double)domainMinimum
{
	if (results[independentIdentifier][@"domainMinimum"])
		return [results[independentIdentifier][@"domainMinimum"] doubleValue];

	if (independentIdentifier==nil || [independentIdentifier isEqualToString:@""])
		return 0;
		
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc]
		initWithKey:independentIdentifier ascending:YES] autorelease
	];
	NSArray *tempData = [data sortedArrayUsingDescriptors:@[sortDescriptor]
	];
		
	double domainMinimum = [tempData[0][independentIdentifier] doubleValue];
	results[independentIdentifier][@"domainMinimum"] = @(domainMinimum);
	ENTRY(NSLog( @"[DataSet domainMinimum] = %f", domainMinimum ));
	return domainMinimum;
}

- (double)globalMinimum
{
	if (results[DSGlobalIdentifier][@"globalMinimum"])
		return [results[DSGlobalIdentifier][@"globalMinimum"] doubleValue];
	ENTRY(NSLog( @"[DataSet globalMinimum]" ));
	[self findGlobalMinAndMax];
	
	return [results[DSGlobalIdentifier][@"globalMinimum"] doubleValue];
}

- (double)minimum
{
	if (results[currentIdentifier][@"minimum"])
		return [results[currentIdentifier][@"minimum"] doubleValue];

	[self sort];

	double minimum = [data[0][currentIdentifier] doubleValue];
	results[currentIdentifier][@"minimum"] = @(minimum);
	ENTRY(NSLog( @"[DataSet minimum] = %f", minimum ));
	return minimum;
}

- (double)firstQuartile
{
	if (results[currentIdentifier][@"firstQuartile"])
		return [results[currentIdentifier][@"firstQuartile"] doubleValue];

	ENTRY(NSLog( @"[DataSet firstQuartile]" ));
	[self sort];
		
	int count = data.count;
	if (count<2)
		return [self minimum];
	int middle = count/4;
	double firstQuartile;
	switch (count%4) {
		case 0:
			firstQuartile = ( 
				[data[middle-1][currentIdentifier] doubleValue] +
				[data[middle][currentIdentifier] doubleValue]
			) / 2;
			break;
		case 1:
			firstQuartile = ( 
				[data[middle-1][currentIdentifier] doubleValue] +
				[data[middle][currentIdentifier] doubleValue]
			) / 2;
			break;
		case 2:
			firstQuartile = [data[middle][currentIdentifier] doubleValue];
			break;
		case 3:
			firstQuartile = [data[middle][currentIdentifier] doubleValue];
			break;
		default:
			NSLog( @"should never get here (bad case in [DataSet firstQuartile] - count: %d %% 4 = %d)",count,count%4 );
			return 0;		
	}
	
	results[currentIdentifier][@"firstQuartile"] = @(firstQuartile);
	return firstQuartile;
}

- (double)median
{
	if (results[currentIdentifier][@"median"])
		return [results[currentIdentifier][@"median"] doubleValue];
	
	ENTRY(NSLog( @"[DataSet media]" ));
	[self sort];
	
	int count = data.count;
	int middle =  count/2;
	double median = 0;
	if (count%2) {
		median = [data[middle][currentIdentifier] doubleValue];
	} else {
		median = ( 
			[data[middle-1][currentIdentifier] doubleValue] +
			[data[middle][currentIdentifier] doubleValue]
		) / 2;
	}
	
	results[currentIdentifier][@"median"] = @(median);
	return median;
}

- (double)thirdQuartile
{
	if (results[currentIdentifier][@"thirdQuartile"])
		return [results[currentIdentifier][@"thirdQuartile"] doubleValue];

	ENTRY(NSLog( @"[DataSet thirdQuartile]" ));
	[self sort];
		
	int count = data.count;
	if (count<2)
		return [self maximum];
	int middle = 3*count/4;
	double thirdQuartile;
	switch (count%4) {
		case 0:
			thirdQuartile = ( 
				[data[middle-1][currentIdentifier] doubleValue] +
				[data[middle][currentIdentifier] doubleValue]
			) / 2;
			break;
		case 1:
			thirdQuartile = ( 
				[data[middle][currentIdentifier] doubleValue] +
				[data[middle+1][currentIdentifier] doubleValue]
			) / 2;
			break;
		case 2:
			thirdQuartile = [data[middle][currentIdentifier] doubleValue];
			break;
		case 3:
			thirdQuartile = [data[middle][currentIdentifier] doubleValue];
			break;
		default:
			NSLog( @"should never get here (bad case in [DataSet thirdQuartile] - count: %d %% 4 = %d)",count,count%4 );
			return 0;
	}
	
	results[currentIdentifier][@"thirdQuartile"] = @(thirdQuartile);
	return thirdQuartile;
}

- (double)maximum
{
	if (results[currentIdentifier][@"maximum"])
		return [results[currentIdentifier][@"maximum"] doubleValue];

	if (data.count<2)
		return [self minimum];

	[self sort];
	
	double maximum = [data[data.count-1][currentIdentifier] doubleValue];
	results[currentIdentifier][@"maximum"] = @(maximum);
	ENTRY(NSLog( @"[DataSet maximum] = %f", maximum ));
	return maximum;
}

- (double)globalMaximum
{
	if (results[DSGlobalIdentifier][@"globalMaximum"])
		return [results[DSGlobalIdentifier][@"globalMaximum"] doubleValue];
	INFO(NSLog( @"[DataSet globalMaximum]" ));
	[self findGlobalMinAndMax];
	
	return [results[DSGlobalIdentifier][@"globalMaximum"] doubleValue];
}

- (double)domainMaximum
{
	if (results[independentIdentifier][@"domainMaximum"])
		return [results[independentIdentifier][@"domainMaximum"] doubleValue];

	if (independentIdentifier==nil || [independentIdentifier isEqualToString:@""])
		return 0;
		
	if (data.count<2)
		return [self domainMinimum];
		
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc]
		initWithKey:independentIdentifier ascending:YES] autorelease
	];
	NSArray *tempData = [data sortedArrayUsingDescriptors:@[sortDescriptor]
	];
	
	double domainMaximum = [tempData[tempData.count-1][independentIdentifier] doubleValue];
	results[independentIdentifier][@"domainMaximum"] = @(domainMaximum);
	ENTRY(NSLog( @"[DataSet domainMaximum] = %f", domainMaximum ));
	return domainMaximum;
}

- (void)findGlobalMinAndMax
{
	ENTRY(NSLog( @"[DataSet findGlobalMinAndMax]" ));
	NSString *origIdent = currentIdentifier;
	double check, globalMin, globalMax;
	NSEnumerator *en = [dataIdentifiers objectEnumerator];
	NSString *tempString;
	tempString = [en nextObject];
	if ([tempString isEqualToString:independentIdentifier])
		tempString = [en nextObject];
	[self setCurrentIdentifier:tempString];
	globalMin = [self minimum];
	globalMax = [self maximum];
	while (tempString=[en nextObject]) {
		if (![tempString isEqualToString:independentIdentifier]) {		
			[self setCurrentIdentifier:tempString];
			check = [self minimum];
			if (check<globalMin)
				globalMin = check;
			check = [self maximum];
			if (check>globalMax)
				globalMax = check;
		}
	}
	[self setCurrentIdentifier:origIdent];
	INFO(NSLog( @"calculated globals( %f, %f )", globalMin, globalMax ));
	results[DSGlobalIdentifier][@"globalMinimum"] = @(globalMin);
	results[DSGlobalIdentifier][@"globalMaximum"] = @(globalMax);
}


@end
