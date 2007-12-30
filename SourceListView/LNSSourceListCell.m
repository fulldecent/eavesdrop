//
//  LNSSourceListCell.m
//  SourceList
//
//  Created by Mark Alldritt on 07/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "LNSSourceListCell.h"
#import "LNSSourceListView.h"


@implementation LNSSourceListCell

+ (NSImage*)branchImage
{
	// Used to prevent the browser cell from drawing it's branch arrow
	return nil;
}

+ (NSImage*)highlightedBranchImage
{
	// Used to prevent the browser cell from drawing it's branch arrow
	return nil;
}

- (id) copyWithZone:(NSZone*) zone
{
	LNSSourceListCell* newCell = [super copyWithZone:zone];
	
	[newCell->mValue retain];
	return newCell;
}

- (void) dealloc
{
	[mValue release];
	[super dealloc];
}

- (NSDictionary*) objectValue	{ return [[NSDictionary dictionary] autorelease]; }
- (void) setObjectValue:(NSDictionary*) value
{
	if (mValue != value)
	{
		[mValue release];
		mValue = [value retain];
		
		if ([mValue isKindOfClass:[NSDictionary class]])
		{
			[self setStringValue:[mValue objectForKey:@"name"]];
		}
		else
		{
			[super setObjectValue:value];
		}
	}
}

- (NSColor*) highlightColorWithFrame:(NSRect) cellFrame inView:(NSView*) controlView
{
	//	The table view does the highlighting.  Returning nil seems to stop the cell from
	//	attempting th highlight the row.
	return nil;
}

- (NSColor *)highlightColorInView:(NSView *)controlView
{
	// This NSBrowserCell's equivalent to highlighColorWithFrame 
	return nil;
}

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[self setImage:[NSImage imageNamed:@"Folder.tif"]];
	
	NSParameterAssert([controlView isKindOfClass:[LNSSourceListView class]]);

	if ([self isHighlighted])
	{
		NSFontManager* fontManager = [NSFontManager sharedFontManager];
		NSString* title = [self stringValue];
		NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:[[self attributedStringValue] attributesAtIndex:0 effectiveRange:NULL]];
		NSFont* font = [attrs objectForKey:NSFontAttributeName];

		switch ([(LNSSourceListView*) controlView appearance])
		{
		default:
		case kSourceList_iTunesAppearance:
			{
				
				[attrs setValue:[fontManager convertFont:font toHaveTrait:NSBoldFontMask] forKey:NSFontAttributeName];
				[attrs setValue:[NSColor darkGrayColor] forKey:NSForegroundColorAttributeName];

				NSSize titleSize = [title sizeWithAttributes:attrs];
				NSRect inset = cellFrame;
				
				inset.size.height = titleSize.height;
				inset.origin.y = NSMinY(cellFrame) + (NSHeight(cellFrame) - titleSize.height) / 2.0;
				if ([self image])
					inset.origin.x += 18; // Have to offset more to allow for the image
				else
					inset.origin.x += 3; // Nasy to hard-code this. Can we get it to draw its own content, or determine correct inset?
				inset.origin.y += 1;

				[title drawInRect:inset withAttributes:attrs];

				inset.origin.y -= 1;
				[attrs setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
				[title drawInRect:inset withAttributes:attrs];
				
				// This is used to draw the image at the side of the row
				if ([self image])
					[[self image] compositeToPoint:NSMakePoint(inset.origin.x-18, inset.origin.y+15) operation:NSCompositeSourceOver];
			}
			break;
		
		case kSourceList_NumbersAppearance:
			{
				NSWindow* window = [controlView window];

				if ([window firstResponder] == controlView && 
					[window isMainWindow] &&
					[window isKeyWindow])
				{
					[attrs setValue:[fontManager convertFont:font toHaveTrait:NSBoldFontMask] forKey:NSFontAttributeName];
					[attrs setValue:[NSColor darkGrayColor] forKey:NSForegroundColorAttributeName];

					NSSize titleSize = [title sizeWithAttributes:attrs];
					NSRect inset = cellFrame;
					
					inset.size.height = titleSize.height;
					inset.origin.y = NSMinY(cellFrame) + (NSHeight(cellFrame) - titleSize.height) / 2.0;
					inset.origin.x += 3; // Nasty to hard-code this. Can we get it to draw its own content, or determine correct inset?
					inset.origin.y += 1;

					[title drawInRect:inset withAttributes:attrs];

					inset.origin.y -= 1;
					[attrs setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
					[title drawInRect:inset withAttributes:attrs];
				}
				else
				{
					[attrs setValue:[fontManager convertFont:font toHaveTrait:NSBoldFontMask] forKey:NSFontAttributeName];
					[attrs setValue:[NSColor darkGrayColor] forKey:NSForegroundColorAttributeName];

					NSSize titleSize = [title sizeWithAttributes:attrs];
					NSRect inset = cellFrame;
					
					inset.size.height = titleSize.height;
					inset.origin.y = NSMinY(cellFrame) + (NSHeight(cellFrame) - titleSize.height) / 2.0;
					inset.origin.x += 3; // Nasty to hard-code this. Can we get it to draw its own content, or determine correct inset?
					[title drawInRect:inset withAttributes:attrs];
				}
			}
			break;
		}
	}
	else
		[super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
