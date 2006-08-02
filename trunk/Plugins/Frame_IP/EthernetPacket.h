//
//  PacketEthernet.h
//  Eavesdrop
//
//  Created by Eric Baur on 6/1/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <EDPlugin/sniff.h>
#import <EDPlugin/Dissector.h>

#import <BHDebug/BHDebug.h>

@interface EthernetPacket : Dissector {

}

//+ (void)initializeClass;

- (NSString *)ethernetDestination;
- (NSString *)ethernetSource;

- (NSNumber *)ethernetProtocol;
- (NSString *)ethernetProtocolString;

@end
