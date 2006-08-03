//
//  TCPAggregateDefaults.m
//  Eavesdrop
//
//  Created by Eric Baur on 7/11/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "TCPAggregateDefaults.h"


@implementation TCPAggregateDefaults

#pragma mark -
#pragma mark Setup methods

- (id)initWithSettings:(NSDictionary *)settingsDict
{
	ENTRY( @"initWithSettings:" );
	self = [super initWithSettings:settingsDict];
	if (self) {
		if ( ![NSBundle loadNibNamed:@"TCPAggregateDefaults" owner:self] ) {
			ERROR( @"failed to load TCPAggregateDefaults nib" );
		}
	}
	return self;
}

#pragma mark -
#pragma mark Accessor methods

#pragma mark -
#pragma mark Overridden methods

- (void)getDefaultsFromDictionary:(NSDictionary *)defaultsDict
{
	[super getDefaultsFromDictionary:defaultsDict];
}

- (NSDictionary *)defaultsDict
{
	NSMutableDictionary *defaultsDict = [[super defaultsDict] mutableCopy];

	return [defaultsDict copy];
}

@end
