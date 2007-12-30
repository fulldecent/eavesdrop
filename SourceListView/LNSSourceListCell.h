//
//  LNSSourceListCell.h
//  SourceList
//
//  Created by Mark Alldritt on 07/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// I'm using a NSBrowserCell here so that we can use a image for the cells with minimal custom code
@interface LNSSourceListCell : NSBrowserCell {//NSTextFieldCell {
	NSDictionary*	mValue;
}

- (NSDictionary*) objectValue;
- (void) setObjectValue:(NSDictionary*) value;

@end
