//
//  BHOutlineView.m
//  Eavesdrop
//
//  Created by Eric Baur on 7/8/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "BHOutlineView.h"

@implementation NSOutlineView (MyExtensions)

- (id)selectedItem { return [self itemAtRow: [self selectedRow]]; }

- (NSArray*)allSelectedItems {
    NSMutableArray *items = [NSMutableArray array];
    NSEnumerator *selectedRows = [self selectedRowEnumerator];
    NSNumber *selRow = nil;
    while( (selRow = [selectedRows nextObject]) ) {
        if ([self itemAtRow:[selRow intValue]]) 
            [items addObject: [self itemAtRow:[selRow intValue]]];
    }
    return items;
}

- (void)selectItems:(NSArray*)items byExtendingSelection:(BOOL)extend {
    int i;
    if (extend==NO) [self deselectAll:nil];
    for (i=0;i<[items count];i++) {
        int row = [self rowForItem:[items objectAtIndex:i]];
        if(row>=0) [self selectRow: row byExtendingSelection:YES];
    }
}

@end

@implementation BHOutlineView

static int colorPercent;

+ (void)initialize
{
	colorPercent = 0;
}
/*
- (void)drawRow:(int)row clipRect:(NSRect)clipRect;
{	
	colorPercent += 5;
	colorPercent %= 100;
	
	DEBUG( @"rect: %@", NSStringFromRect(clipRect) );
	
	NSColor *color = [NSColor colorWithDeviceRed:0 green:((double)colorPercent/100.0) blue:0 alpha:0.5];
	[color set];
	NSRectFill(clipRect);
	
	
    [super drawRow:row clipRect:clipRect];
}
*/

/*
// not working
- (id)_backgroundColorForCell:(id)cell
{
	return [NSColor blueColor];
}

//does work
-(id)_highlightColorForCell:(id)cell
{
	return [NSColor redColor];
}
*/

#pragma mark -
#pragma mark Overrides (NSTableView)

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset
{
	ENTRY;

	const int defaultWidth = 32;
	const int defaultHeight = 32;

	//get our background image and set it's size
	NSImage *earImage = [NSImage imageNamed:@"Ear icon.icns"];
	[earImage setSize:NSMakeSize( defaultWidth, defaultHeight )];
	
	//figure out how many packets we have
	NSString *numberString = [NSString stringWithFormat:@"%d", [dragRows count] ];
	NSSize stringSize = [numberString sizeWithAttributes:nil];
	
	//make sure the drage image is big enough to hold the entire string
	int imageWidth, imageHeight;
	imageWidth = ( stringSize.width*2 > defaultWidth ? stringSize.width*2 : defaultWidth );
	imageHeight = ( stringSize.height > defaultHeight ? stringSize.height : defaultHeight );

	//create a blank image for working on
	NSImage *dragImage = [[NSImage alloc] initWithSize:NSMakeSize( imageWidth, imageHeight )];
	[dragImage lockFocus];
	
	//draw the oval behind the number
	[[NSColor blueColor] set];
	NSBezierPath *path;
	path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0,0,2*stringSize.width,stringSize.height)];
	[path fill];
	
	//draw the number of packets in white
	[numberString drawAtPoint: NSMakePoint(0.5*stringSize.width,0)
		withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSColor whiteColor],		NSForegroundColorAttributeName,
			nil
		]
	];
	
	//composite the number oval ontop of the ear icon
	[earImage compositeToPoint: NSMakePoint(0, 0) operation:NSCompositeDestinationOver];
	
	[dragImage unlockFocus];
	
	//calculate the image offset
	dragImageOffset->x = ( imageWidth / 2 ) - ( 1.5 * stringSize.width );
	dragImageOffset->y = imageHeight / 2;

	return dragImage;
}



@end
