//
//  Dissector.h
//  Eavesdrop
//
//  Created by Eric Baur on 6/19/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Plugin.h"
#import "PluginDefaults.h"

@protocol Dissector <Plugin>

+ (BOOL)canDecodePacket:(NSObject<Plugin> *)testPacket;								/* FREEBIE	*/

- (id)initFromParent:(id)parentPacket;												/* RECOMMENDED */
- (id)initWithHeaderData:(NSData *)newHeader packetData:(NSData *)newPacket;		/* FREEBIE	*/

- (NSString *)preferedDissectorProtocol;											/* RECOMMENDED */

- (NSData *)headerData;																/* REQUIRED */
- (NSData *)payloadData;															/* REQUIRED */
//- (NSData *)packetData;																/* FREEBIE	*/

- (const void *)headerBytes;														/* FREEBIE	*/
- (const void *)payloadBytes;														/* FREEBIE	*/
//- (const void *)packetBytes;														/* FREEBIE	*/

- (NSArray *)detailColumnsArray;

@end


@interface Dissector : Plugin <Dissector> {
	int dissectorNumber;

	NSData *headerData;
	NSData *payloadData;
	//NSData *packetData;
	
	NSObject<Dissector> *parent;
	NSObject<Dissector> *child;
}

+ (id)packetWithHeaderData:(NSData *)newHeader packetData:(NSData *)newPacket;

@end
