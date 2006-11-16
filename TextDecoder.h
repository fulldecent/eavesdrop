//
//  TextDecoder.h
//  Eavesdrop
//
//  Created by Eric Baur on 11/11/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#define CONVERSATION_ASCII		0
#define CONVERSATION_HEX		1
#define CONVERSATION_HEX_ASCII	2

#import <Cocoa/Cocoa.h>

#import "Decoder.h"

@interface TextDecoder : Decoder {
	IBOutlet NSView *textDecoderView;
	
	int representation;
}

@end
