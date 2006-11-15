//
//  TextDecoder.m
//  Eavesdrop
//
//  Created by Eric Baur on 11/11/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "TextDecoder.h"


@implementation TextDecoder

+ (BOOL)canDecodePayload:(NSData *)payload
{
	if ( [payload length] > 0 )
		return YES;
	else
		return NO;
}

- (id)initWithPayload:(NSData *)startingPayload
{
	self = [super init];
	if (self) {
		//do something interesting here...
	}
	return self;
}

- (void)awakeFromNib
{
	ENTRY1( @"awakeFromNib - text view: %@", [textDecoderView description] );
}

- (NSView *)textDecoderView
{
	ENTRY( @"textDecoderView" );
	return textDecoderView;
}

@end
