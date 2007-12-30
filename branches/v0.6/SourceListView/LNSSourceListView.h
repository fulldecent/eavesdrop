/* LNSSourceListView */

#import <Cocoa/Cocoa.h>


typedef enum {
	kSourceList_iTunesAppearance,	// gradient selection backgrounds
	kSourceList_NumbersAppearance	// flat selection backgrounds
} AppearanceKind;


@interface LNSSourceListView : NSOutlineView
{
	AppearanceKind	mAppearance;
}

- (AppearanceKind) appearance;
- (void) setAppearance:(AppearanceKind) newAppearance;

@end
