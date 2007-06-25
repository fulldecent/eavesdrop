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
	ENTRY( @"canDecodePayload: (default implementation)" );
	return NO;
}

+ (BOOL)canDecodePayload:(NSData *)payload fromDissector:(id<Dissector>)dissector;
{
	ENTRY( @"canDecodePayload:fromDissector: (default implementation)" );
	return NO;
}

+ (BOOL)canDecodePayload:(NSData *)payload fromAggregate:(id<Aggregate>)aggregate
{
	ENTRY( @"canDecodePayload:fromAggregate: (default implementation)" );
	return NO;
}

#pragma mark - 
#pragma mark Setup methods

- (id)initWithObject:(Plugin *)object
{
	//ENTRY1( @"initWithObject: %@", [object description] );
	return [self initWithPayload:[object valueForKey:@"payloadData"] ];
}

- (id)initWithPayload:(NSData *)startingPayload
{
	//ENTRY( @"initWithPayload: (default implementation)" );
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
	//ENTRY( @"initWithPayload:fromDissector: (default implementation)" );
	return [self initWithPayload:startingPayload];
}

- (id)initWithPayload:(NSData *)startingPayload fromAggregate:(id<Aggregate>)startingAaggregate;
{
	//ENTRY( @"initWithPayload:fromAggregate: (default implementation)" );
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
	//ENTRY1( @"_loadNib: %@", nibName );
	if (!nibLoaded && nibName ) {
		if ( ![NSBundle loadNibNamed:nibName owner:self] ) {
			ERROR1( @"failed to load nib: %@", nibName );
		} else {
			nibLoaded = YES;
		}
	}
}

@end
