//
//  Decoder.m
//  Eavesdrop
//
//  Created by Eric Baur on 11/11/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "Decoder.h"


@implementation Decoder

#pragma mark - 
#pragma mark Decision Class methods

+ (BOOL)canDecodePayload:(NSData *)payload
{
	ENTRY;
	return NO;
}

+ (BOOL)canDecodePayload:(NSData *)payload fromDissector:(id<Dissector>)dissector;
{
	ENTRY;
	return NO;
}

+ (BOOL)canDecodePayload:(NSData *)payload fromAggregate:(id<Aggregate>)aggregate
{
	ENTRY;
	return NO;
}

#pragma mark - 
#pragma mark Setup methods

- (id)initWithObject:(Plugin *)object
{
	return [self initWithPayload:[object valueForKey:@"payloadData"] ];
}

- (id)initWithPayload:(NSData *)startingPayload
{
	self = [super init];
	if (self) {
		payloadData = [startingPayload retain];
		nibLoaded = NO;
		[self _loadNib];
	}
	return self;
}

- (id)initWithPayload:(NSData *)startingPayload fromDissector:(id<Dissector>)startingDissector;
{
	return [self initWithPayload:startingPayload];
}

- (id)initWithPayload:(NSData *)startingPayload fromAggregate:(id<Aggregate>)startingAaggregate;
{
	return [self initWithPayload:startingPayload];
}

#pragma mark -
#pragma mark Private methods

- (NSString *)decoderNibName
{
	return nil;
}

- (void)_loadNib
{
	NSString *nibName = [self decoderNibName];
	if (!nibLoaded && nibName ) {
		if ( ![NSBundle loadNibNamed:nibName owner:self] ) {
			ERROR( @"failed to load nib: %@", nibName );
		} else {
			nibLoaded = YES;
		}
	}
}

@end
