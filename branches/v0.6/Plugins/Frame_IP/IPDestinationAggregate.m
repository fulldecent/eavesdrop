//
//  IPDestinationAggregate.m
//  Eavesdrop
//
//  Created by Eric Baur on 6/18/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "IPDestinationAggregate.h"

@implementation IPDestinationAggregate

+ (NSString *)aggregateIdentifierForPacket:(NSObject<Dissector> *)newPacket
{
	NSString *tempValue = [newPacket valueForKey:@"ipDestination"];
	if ( tempValue )
		return tempValue;
	else
		return nil;
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
