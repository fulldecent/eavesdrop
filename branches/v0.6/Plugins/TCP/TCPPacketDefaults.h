//
//  TCPPacketDefaults.h
//  Eavesdrop
//
//  Created by Eric Baur on 7/11/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <EDPlugin/PluginDefaults.h>

@interface TCPPacketDefaults : PluginDefaults {
	NSMutableArray *flagsArray;
	id currentFlagSelection;
}

- (NSMutableArray *)flagsArray;
- (NSMutableDictionary *)flagsDictionary;

@end
