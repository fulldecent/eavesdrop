//
//  BHLog_Viewer_AppDelegate.h
//  BHLog Viewer
//
//  Created by Eric Baur on 11/17/06.
//  Copyright Eric Shore Baur 2006 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "BHLogging.h"

@interface BHLog_Viewer_AppDelegate : NSObject <BHLogging>
{
    IBOutlet NSWindow *window;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	
	NSMutableArray *logLevels;
	NSMutableDictionary *appObjects;
	NSMutableDictionary *classObjects;
	
	NSPredicate *filterPredicate;
	IBOutlet NSArrayController *classesArrayController;
	IBOutlet NSArrayController *logEntriesArrayController;
	IBOutlet NSArrayController *applicationsArrayController;
	
	IBOutlet NSTableView *classesTableView;
	IBOutlet NSTableView *logEntriesTableView;
	IBOutlet NSTableView *applicationsTableView;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (IBAction)saveAction:(id)sender;
- (IBAction)refreshLog:(id)sender;

- (NSPredicate *)filterPredicate;
- (void)setFilterPredicate:(NSPredicate *)newFilterPredicate;

- (IBAction)checkAllClasses:(id)sender;
- (IBAction)uncheckAllClasses:(id)sender;

@end
