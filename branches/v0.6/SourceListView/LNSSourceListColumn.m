//
//  LNSSourceListColumn.m
//  SourceList
//
//  Created by Mark Alldritt on 07/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "LNSSourceListColumn.h"
#import "LNSSourceListCell.h"
#import "LNSSourceListSourceGroupCell.h"


@implementation LNSSourceListColumn

- (void) awakeFromNib
{
	LNSSourceListCell* dataCell = [[[LNSSourceListCell alloc] init] autorelease];

	[dataCell setFont:[[self dataCell] font]];
	[dataCell setLineBreakMode:[[self dataCell] lineBreakMode]];

	[self setDataCell:dataCell];
}

- (id) dataCellForRow:(int) row
{
	if (row >= 0)
	{
		NSDictionary* value = [[(NSOutlineView*) [self tableView] itemAtRow:row] representedObject];

		if ([[value objectForKey:@"isSourceGroup"] boolValue])
		{
			LNSSourceListSourceGroupCell* groupCell = [[[LNSSourceListSourceGroupCell alloc] init] autorelease];
			
			[groupCell setFont:[[self dataCell] font]];
			[groupCell setLineBreakMode:[[self dataCell] lineBreakMode]];
			return groupCell;			
		}
	}

	return [self dataCell];
}

@end
