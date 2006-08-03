//
//  TCPPacket.h
//  Eavesdrop
//
//  Created by Eric Baur on 6/9/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <EDPlugin/Dissector.h>

#import <EDPlugin/sniff.h>

@interface TCPPacket : Dissector {

}


- (NSNumber *)tcpAcknowledgement;
- (NSString *)tcpFlags;
- (NSNumber *)tcpDestinationPort;
- (NSNumber *)tcpSequence;
- (NSNumber *)tcpSourcePort;
- (NSNumber *)tcpWindow;

@end
