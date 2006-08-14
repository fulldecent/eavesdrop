//
//  IPSourceAggregator.m
//  Eavesdrop
//
//  Created by Eric Baur on 6/13/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "IPSourceAggregate.h"

@implementation IPSourceAggregate

#pragma mark -
#pragma mark Protocol Class methods

+ (NSDictionary *)keyNames
{
	//no additional keys defined for this aggregator
	return [NSDictionary dictionary];
}

+ (NSString *)aggregateIdentifierForPacket:(NSObject<Dissector> *)newPacket
{
	NSString *tempValue = [newPacket valueForKey:@"ipSource"];
	if ( tempValue )
		return tempValue;
	else
		return nil;
}

- (NSString *)sourceString
{
	return identifier;
}

- (NSString *)typeString
{
	return @"IP Source";
}

@end
