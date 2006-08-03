//
//  BHDebug.h
//  Eavesdrop
//
//  Created by Eric Baur on 6/13/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ERROR(string)				[BHDebug logError:string forObject:self];
#define ERROR1(string,arg1)			[BHDebug logError:[NSString stringWithFormat:string, arg1] forObject:self];
#define ERROR2(string,arg1,arg2)	[BHDebug logError:[NSString stringWithFormat:string, arg1, arg2] forObject:self];

#define WARNING(string)				[BHDebug logWarning:string forObject:self];
#define WARNING1(string,arg1)		[BHDebug logWarning:[NSString stringWithFormat:string, arg1] forObject:self];
#define WARNING2(string,arg1,arg2)	[BHDebug logWarning:[NSString stringWithFormat:string, arg1, arg2] forObject:self];

#define DEBUG(string)				[BHDebug logDebug:string forObject:self];
#define DEBUG1(string,arg1)			[BHDebug logDebug:[NSString stringWithFormat:string, arg1] forObject:self];
#define DEBUG2(string,arg1,arg2)	[BHDebug logDebug:[NSString stringWithFormat:string, arg1, arg2] forObject:self];

#define INFO(string)				[BHDebug logInfo:string forObject:self];
#define INFO1(string,arg1)			[BHDebug logInfo:[NSString stringWithFormat:string,arg1] forObject:self];
#define INFO2(string,arg1,arg2)		[BHDebug logInfo:[NSString stringWithFormat:string, arg1, arg2] forObject:self];

#define ENTRY(string)				[BHDebug logEntry:string forObject:self];
#define ENTRY1(string,arg1)			[BHDebug logEntry:[NSString stringWithFormat:string,arg1] forObject:self];
#define ENTRY2(string,arg1,arg2)	[BHDebug logEntry:[NSString stringWithFormat:string, arg1, arg2] forObject:self];

#define EXIT(string)				[BHDebug logExit:string forObject:self];
#define EXIT1(string,arg1)			[BHDebug logExit:[NSString stringWithFormat:string, arg1] forObject:self];
#define EXIT2(string,arg1,arg2)		[BHDebug logExit:[NSString stringWithFormat:string, arg1, arg2] forObject:self];

@interface BHDebug : NSObject {

}

+ (void)logError:(NSString *)text forObject:(id)sender;
+ (void)logWarning:(NSString *)text forObject:(id)sender;
+ (void)logDebug:(NSString *)text forObject:(id)sender;
+ (void)logInfo:(NSString *)text forObject:(id)sender;

+ (void)logEntry:(NSString *)text forObject:(id)sender;
+ (void)logExit:(NSString *)text forObject:(id)sender;

@end
