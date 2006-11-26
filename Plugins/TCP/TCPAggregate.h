//
//  TCPAggregate.h
//  Eavesdrop
//
//  Created by Eric Baur on 6/18/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <EDPlugin/Packet.h>
#import <EDPlugin/Aggregate.h>

@interface TCPAggregate : Aggregate {
	NSObject<Dissector> *firstPacket;

	IBOutlet NSView *tcpPayloadTextView;
	IBOutlet NSView *tcpPayloadImageView;
}

@end
