//
//  TCPServerPortAggregateDefaults.h
//  Eavesdrop
//
//  Created by Eric Baur on 10/15/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <EDPlugin/PluginDefaults.h>

@interface TCPServerPortAggregateDefaults : PluginDefaults {
	BOOL useLowPort;
	NSMutableArray *portsArray;
}

- (NSMutableArray *)portsArray;

@end
