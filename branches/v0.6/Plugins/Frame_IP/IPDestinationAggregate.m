//
//  IPDestinationAggregate.m
//  Eavesdrop
//
//  Created by Eric Baur on 6/18/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "IPDestinationAggregate.h"

@implementation IPDestinationAggregate

+ (NSDictionary *)keyNames
{
	//no additional keys defined for this aggregator
	return [NSDictionary dictionary];
}

+ (NSString *)aggregateIdentifierForPacket:(NSObject<Dissector> *)newPacket
{
	NSString *tempValue = [newPacket valueForKey:@"ipDestination"];
	if ( tempValue )
		return tempValue;
	else
		return @"n/a";
}

- (NSString *)destinationString
{
	return identifier;
}

- (NSString *)typeString
{
	return @"IP Destination";
}


@end
