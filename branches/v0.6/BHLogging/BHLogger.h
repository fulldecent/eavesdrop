//
//  BHLogger.h
//  BHLogger
//
//  Created by Eric Baur on 6/13/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "BHLogging.h"
//#import "BHLog_Viewer_AppDelegate.h"

@interface BHLogger : NSObject {

}


//+ (void)logObject:(id)sender atLevel:(int)logLevel withFormat:(id)format, ...;

+ (void)log:(NSString *)text forObject:(id)sender as:(int)logLevel;

NSString* stringForLevel( int logLevel );

@end
/*
inline void LogError( id object, id format, ... )
{
	va_list argList;
	va_start( argList, format );
	[BHLogger
		log:(NSString *)CFStringCreateWithFormatAndArguments( NULL, NULL, (CFStringRef)format, argList )
		forObject:object
		at:1
	];
	va_end( argList );
}
*/