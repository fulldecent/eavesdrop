//
//  TextDecoder.h
//  Eavesdrop
//
//  Created by Eric Baur on 11/11/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Decoder.h"

typedef enum TextRepresentation {
	TextRepresentationASCII		= 0,
	TextRepresentationHex		= 1,
	TextRepresentationHexASCII	= 2
} TextRepresentation;

@interface TextDecoder : Decoder {
	IBOutlet NSView *textDecoderView;
	
	TextRepresentation representation;
	NSAttributedString *payloadString;
}


- (NSView *)textDecoderView;
- (void)setRepresentation:(TextRepresentation)newRep;

- (NSAttributedString *)payloadAsAttributedString;

@end
