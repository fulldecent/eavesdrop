#import "LNSSourceListView.h"
#import "LNSSourceListCell.h"


@interface LNSSourceListView (Private)

- (BOOL) _itemIsSourceGroup:(id) item;

@end

@implementation LNSSourceListView (Private)

- (BOOL) _itemIsSourceGroup:(id) item
{
	NSDictionary* value = [item representedObject];

	return [[value objectForKey:@"isSourceGroup"] boolValue];
}

@end
 

@implementation LNSSourceListView

- (void) awakeFromNib
{
	[self setDelegate:self];
}

//	Delegate method
- (BOOL) outlineView:(NSOutlineView*) outlineView shouldSelectItem:(id) item
{
	//	Don't allow the user to select Source Groups
	return ![self _itemIsSourceGroup:item];
}

- (float) outlineView:(NSOutlineView*) outlineView heightOfRowByItem:(id) item
{
	//	Make the height of Source Group items a little higher
	if ([self _itemIsSourceGroup:item])
		return [self rowHeight] + 4.0;
	return [self rowHeight];
}

- (AppearanceKind) appearance { return mAppearance; }
- (void) setAppearance:(AppearanceKind) newAppearance
{
	if (mAppearance != newAppearance)
	{
		mAppearance = newAppearance;
		[self setNeedsDisplay:YES];
	}
}

- (void) outlineViewSelectionDidChange:(NSNotification*) notification
{
	if (mAppearance == kSourceList_NumbersAppearance && [[self selectedRowIndexes] count] > 1)
		[self setNeedsDisplay:YES];
}

- (void) outlineViewSelectionIsChanging:(NSNotification*) notification
{
	if (mAppearance == kSourceList_NumbersAppearance && [[self selectedRowIndexes] count] > 1)
		[self setNeedsDisplay:YES];
}

- (void) highlightSelectionInClipRect:(NSRect)clipRect
{
	switch (mAppearance)
	{
	default:
	case kSourceList_iTunesAppearance:
		{
			//	This code is cribbed from iTableTextCell.... and draws the highlight for the selected
			//	cell.

			NSRange rows = [self rowsInRect:clipRect];
			unsigned maxRow = NSMaxRange(rows);
			unsigned row;
			NSImage *gradient;
			/* Determine whether we should draw a blue or grey gradient. */
			/* We will automatically redraw when our parent view loses/gains focus, 
				or when our parent window loses/gains main/key status. */
			if (([[self window] firstResponder] == self) && 
					[[self window] isMainWindow] &&
					[[self window] isKeyWindow]) {
				gradient = [NSImage imageNamed:@"highlight_blue.tiff"];
			} else {
				gradient = [NSImage imageNamed:@"highlight_grey.tiff"];
			}
			
			/* Make sure we draw the gradient the correct way up. */
			[gradient setFlipped:YES];
			
			for (row = rows.location; row < maxRow; ++row)
			{
				if ([self isRowSelected:row])
				{
					NSRect selectRect = [self rectOfRow:row];

					if (NSIntersectsRect(selectRect, clipRect))
					{
						int i = 0;
						
						/* We're selected, so draw the gradient background. */
						NSSize gradientSize = [gradient size];
						for (i = selectRect.origin.x; i < (selectRect.origin.x + selectRect.size.width); i += gradientSize.width) {
							[gradient drawInRect:NSMakeRect(i, selectRect.origin.y, gradientSize.width, selectRect.size.height)
									fromRect:NSMakeRect(0, 0, gradientSize.width, gradientSize.height)
								   operation:NSCompositeSourceOver
									fraction:1.0];
						}
					}
				}
			}
		}
		break;

	case kSourceList_NumbersAppearance:
		{
			NSRange rows = [self rowsInRect:clipRect];
			unsigned maxRow = NSMaxRange(rows);
			unsigned row, lastSelectedRow = NSNotFound;
			NSColor* highlightColor = nil;
			NSColor* highlightFrameColor = nil;

			if ([[self window] firstResponder] == self && 
				[[self window] isMainWindow] &&
				[[self window] isKeyWindow])
			{
				highlightColor = [NSColor colorWithCalibratedRed:98.0 / 256.0 green:120.0 / 256.0 blue:156.0 / 256.0 alpha:1.0];
				highlightFrameColor = [NSColor colorWithCalibratedRed:83.0 / 256.0 green:103.0 / 256.0 blue:139.0 / 256.0 alpha:1.0];
			}
			else
			{
				highlightColor = [NSColor colorWithCalibratedRed:160.0 / 256.0 green:160.0 / 256.0 blue:160.0 / 256.0 alpha:1.0];
				highlightFrameColor = [NSColor colorWithCalibratedRed:150.0 / 256.0 green:150.0 / 256.0 blue:150.0 / 256.0 alpha:1.0];
			}

			for (row = rows.location; row < maxRow; ++row)
			{
				if (lastSelectedRow != NSNotFound && row != lastSelectedRow + 1)
				{
					NSRect selectRect = [self rectOfRow:lastSelectedRow];
					
					[highlightFrameColor set];
					selectRect.origin.y += NSHeight(selectRect) - 1.0;
					selectRect.size.height = 1.0;
					NSRectFill(selectRect);
					lastSelectedRow = NSNotFound;
				}
				
				if ([self isRowSelected:row])
				{
					NSRect selectRect = [self rectOfRow:row];

					if (NSIntersectsRect(selectRect, clipRect))
					{
						[highlightColor set];
						NSRectFill(selectRect);
						
						if (row != lastSelectedRow + 1)
						{
							selectRect.size.height = 1.0;
							[highlightFrameColor set];
							NSRectFill(selectRect);
						}
					}

					lastSelectedRow = row;
				}
			}

			if (lastSelectedRow != NSNotFound)
			{
				NSRect selectRect = [self rectOfRow:lastSelectedRow];
				
				[highlightFrameColor set];
				selectRect.origin.y += NSHeight(selectRect) - 1.0;
				selectRect.size.height = 1.0;
				NSRectFill(selectRect);
				lastSelectedRow = NSNotFound;
			}
		}
		break;
	}
}

@end
