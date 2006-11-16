//
//  ImageDecoder.h
//  Eavesdrop
//
//  Created by Eric Baur on 11/14/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Decoder.h"

@interface ImageDecoder : Decoder {
	IBOutlet NSView *imageDecoderView;
}

- (NSView *)imageDecoderView;

@end
