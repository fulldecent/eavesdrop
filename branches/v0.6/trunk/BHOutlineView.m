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

- (void)drawRow:(int)row clipRect:(NSRect)clipRect;
{
	//ENTRY( @"drawRow:clipRect:" );
	
	colorPercent += 5;
	colorPercent %= 100;
	
	DEBUG1( @"rect: %@", NSStringFromRect(clipRect) );
	
	NSColor *color = [NSColor colorWithDeviceRed:0 green:((double)colorPercent/100.0) blue:0 alpha:0.5];
	[color set];
	NSRectFill(clipRect);
	
	
    [super drawRow:row clipRect:clipRect];
}

- (id)_backgroundColorForCell:(id)cell
{
	return [NSColor grayColor];
}

-(id)_highlightColorForCell:(id)cell
{
	//ENTRY( @"_highlightColorForCell:" );
	return [NSColor redColor];
}



@end
