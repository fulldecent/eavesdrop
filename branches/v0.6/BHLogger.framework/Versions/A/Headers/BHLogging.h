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
#define BHLoggerDebug	4
#define BHLoggerInfo	8
#define BHLoggerEntry	16
#define BHLoggerExit	32

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
#define BHLoggerExitColor		[NSColor brownColor]

#define ERROR(string,...)	[BHLogger log:[NSString stringWithFormat:string,##__VA_ARGS__] forObject:self method:_cmd filename:__FILE__ lineNumber:__LINE__ as:BHLoggerError];
#define WARNING(string,...)	[BHLogger log:[NSString stringWithFormat:string,##__VA_ARGS__] forObject:self method:_cmd filename:__FILE__ lineNumber:__LINE__ as:BHLoggerWarning];
#define DEBUG(string,...)	[BHLogger log:[NSString stringWithFormat:string,##__VA_ARGS__] forObject:self method:_cmd filename:__FILE__ lineNumber:__LINE__ as:BHLoggerDebug];
#define INFO(string,...)	[BHLogger log:[NSString stringWithFormat:string,##__VA_ARGS__] forObject:self method:_cmd filename:__FILE__ lineNumber:__LINE__ as:BHLoggerInfo];
#define ENTRY				[BHLogger log:nil forObject:self method:_cmd filename:__FILE__ lineNumber:__LINE__ as:BHLoggerEntry];
#define EXIT				[BHLogger log:nil forObject:self method:_cmd filename:__FILE__ lineNumber:__LINE__ as:BHLoggerExit];
#define RETURN(string,...)	[BHLogger log:[NSString stringWithFormat:string,##__VA_ARGS__] forObject:self method:_cmd filename:__FILE__ lineNumber:__LINE__ as:BHLoggerExit];

@protocol BHLogging

- (oneway void)logDetails:(NSDictionary *)detailsDict;

@end
