//
//  Packet.h
//  Eavesdrop
//
//  Created by Eric Baur on 5/28/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "sniff.h"
#import "Dissector.h"

@interface Packet : Dissector {
	int packetNumber;
}

- (NSNumber *)captureLength;
- (NSNumber *)length;
- (NSDate *)timestamp;
- (NSString *)timeString;

@end
