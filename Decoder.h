//
//  Decoder.h
//  Eavesdrop
//
//  Created by Eric Baur on 11/11/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Plugin.h"
#import "Dissector.h"
#import "Aggregate.h"

@protocol Decoder <Plugin>

// one of the next three have to be implemented
+ (BOOL)canDecodePayload:(NSData *)payload;
+ (BOOL)canDecodePayload:(NSData *)payload fromDissector:(id<Dissector>)dissector;
+ (BOOL)canDecodePayload:(NSData *)payload fromAggregate:(id<Aggregate>)aggregate;

// whichever one above is implemented, the matching version here should be
- (id)initWithObject:(Plugin *)object;

- (id)initWithPayload:(NSData *)startingPayload;
- (id)initWithPayload:(NSData *)startingPayload fromDissector:(id<Dissector>)startingDissector;
- (id)initWithPayload:(NSData *)startingPayload fromAggregate:(id<Aggregate>)startingAggregate;

@end

@interface Decoder : Plugin <Decoder> {
	BOOL nibLoaded;
	NSData *payloadData;
}

- (NSString *)decoderNibName;

- (void)_loadNib;

@end
