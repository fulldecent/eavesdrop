//
//  TCPServerPortAggregate.h
//  Eavesdrop
//
//  Created by Eric Baur on 10/15/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <EDPlugin/Packet.h>
#import <EDPlugin/Aggregate.h>

#import "TCPServerPortAggregateDefaults.h"

@interface TCPServerPortAggregate : Aggregate {

}

+ (void)resetServerPortsFromDefaults;

@end
