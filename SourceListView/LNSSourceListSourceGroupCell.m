//
//  LNSSourceListSourceGroupCell.m
//  SourceList
//
//  Created by Mark Alldritt on 07/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "LNSSourceListSourceGroupCell.h"

//	A source group is the unselectable (grayed out) group at the top of the source list
//	hierarchy.

@implementation LNSSourceListSourceGroupCell


- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSFontManager* fontManager = [NSFontManager sharedFontManager];
	NSString* title = [[self stringValue] uppercaseString];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:[[self attributedStringValue] attributesAtIndex:0 effectiveRange:NULL]];
	NSFont* font = [attrs objectForKey:NSFontAttributeName];

	[attrs setValue:[fontManager convertFont:font toHaveTrait:NSBoldFontMask] forKey:NSFontAttributeName];
	[attrs setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];

	NSSize titleSize = [title sizeWithAttributes:attrs];
	NSRect inset = cellFrame;
	
	inset.size.height = titleSize.height;
	inset.origin.y = NSMinY(cellFrame) + (NSHeight(cellFrame) - titleSize.height) / 2.0;
	inset.origin.x += 3; // Nasty to hard-code this. Can we get it to draw its own content, or determine correct inset?
	inset.origin.y += 1;

	[title drawInRect:inset withAttributes:attrs];

	inset.origin.y -= 1;
	[attrs setValue:[NSColor darkGrayColor] forKey:NSForegroundColorAttributeName];
	[title drawInRect:inset withAttributes:attrs];
}

@end
