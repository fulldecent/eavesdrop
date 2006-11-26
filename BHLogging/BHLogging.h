//
//  BHLogger.h
//  BHLogger
//
//  Created by Eric Baur on 6/13/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "BHLogger.h"

#define BHLoggerError	1
#define BHLoggerWarning	2
#define BHLoggerDebug	3
#define BHLoggerInfo	4
#define BHLoggerEntry	5
#define BHLoggerExit	6

#define BHLoggerErrorString		@"ERROR"
#define BHLoggerWarningString	@"WARNING"
#define BHLoggerDebugString		@"DEBUG"
#define BHLoggerInfoString		@"INFO"
#define BHLoggerEntryString		@"ENTRY"
#define BHLoggerExitString		@"EXIT"

#define BHLoggerErrorColor		[NSColor redColor]
#define BHLoggerWarningColor	[NSColor orangeColor]
#define BHLoggerDebugColor		[NSColor blueColor]
#define BHLoggerInfoColor		[NSColor grayColor]
#define BHLoggerEntryColor		[NSColor greenColor]
#define BHLoggerExitColor		[NSColor yellowColor]

#define ERROR(string)				[BHLogger log:string forObject:self as:BHLoggerError];
#define ERROR1(string,arg1)			[BHLogger log:[NSString stringWithFormat:string, arg1] forObject:self as:BHLoggerError];
#define ERROR2(string,arg1,arg2)	[BHLogger log:[NSString stringWithFormat:string, arg1, arg2] forObject:self as:BHLoggerError];

#define WARNING(string)				[BHLogger log:string forObject:self as:BHLoggerWarning];
#define WARNING1(string,arg1)		[BHLogger log:[NSString stringWithFormat:string, arg1] forObject:self as:BHLoggerWarning];
#define WARNING2(string,arg1,arg2)	[BHLogger log:[NSString stringWithFormat:string, arg1, arg2] forObject:self as:BHLoggerWarning];

#define DEBUG(string)				[BHLogger log:string forObject:self as:BHLoggerDebug];
#define DEBUG1(string,arg1)			[BHLogger log:[NSString stringWithFormat:string, arg1] forObject:self as:BHLoggerDebug];
#define DEBUG2(string,arg1,arg2)	[BHLogger log:[NSString stringWithFormat:string, arg1, arg2] forObject:self as:BHLoggerDebug];

#define INFO(string)				[BHLogger log:string forObject:self as:BHLoggerInfo];
#define INFO1(string,arg1)			[BHLogger log:[NSString stringWithFormat:string,arg1] forObject:self as:BHLoggerInfo];
#define INFO2(string,arg1,arg2)		[BHLogger log:[NSString stringWithFormat:string, arg1, arg2] forObject:self as:BHLoggerInfo];

#define ENTRY(string)				[BHLogger log:string forObject:self as:BHLoggerEntry];
#define ENTRY1(string,arg1)			[BHLogger log:[NSString stringWithFormat:string,arg1] forObject:self as:BHLoggerEntry];
#define ENTRY2(string,arg1,arg2)	[BHLogger log:[NSString stringWithFormat:string, arg1, arg2] forObject:self as:BHLoggerEntry];

#define EXIT(string)				[BHLogger log:string forObject:self as:BHLoggerExit];
#define EXIT1(string,arg1)			[BHLogger log:[NSString stringWithFormat:string, arg1] forObject:self as:BHLoggerExit];
#define EXIT2(string,arg1,arg2)		[BHLogger log:[NSString stringWithFormat:string, arg1, arg2] forObject:self as:BHLoggerExit];

@protocol BHLogging

- (oneway void)logDetails:(NSDictionary *)detailsDict;

@end
