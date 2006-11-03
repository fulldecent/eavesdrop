//
//  IPPacket.h
//  Eavesdrop
//
//  Created by Eric Baur on 6/1/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <EDPlugin/sniff.h>
#import <EDPlugin/Dissector.h>

#import <BHDebug/BHDebug.h>

@interface IPPacket : Dissector {

}

- (NSString *)ipDestination;
- (NSNumber *)ipProtocol;
- (NSString *)ipProtocolString;
- (NSString *)ipSource;

- (NSData *)ipHeaderData;
- (NSData *)ipPayloadData;

- (NSNumber *)ipHeaderLength;
- (NSNumber *)ipPayloadLength;
@end
