//
//  BHDebug.m
//  Eavesdrop
//
//  Created by Eric Baur on 6/13/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "BHDebug.h"

@implementation BHDebug

+ (void)logError:(NSString *)text forObject:(id)sender
{
	NSLog( @"[%@] ERROR -%@- %@", [[NSThread currentThread] valueForKey:@"seqNum"], [sender className], text );
}

+ (void)logWarning:(NSString *)text forObject:(id)sender
{
	NSLog( @"[%@] WARNING -%@- %@", [[NSThread currentThread] valueForKey:@"seqNum"], [sender className], text );
}

+ (void)logDebug:(NSString *)text forObject:(id)sender
{
	NSLog( @"[%@] DEBUG -%@- %@", [[NSThread currentThread] valueForKey:@"seqNum"], [sender className], text );
}

+ (void)logInfo:(NSString *)text forObject:(id)sender
{
	NSLog( @"[%@] INFO -%@-\n%@", [[NSThread currentThread] valueForKey:@"seqNum"], [sender className], text );
}

+ (void)logEntry:(NSString *)text forObject:(id)sender
{
	NSLog( @"[%@] ENTRY -%@- %@", [[NSThread currentThread] valueForKey:@"seqNum"], [sender className], text );
}

+ (void)logExit:(NSString *)text forObject:(id)sender
{
	NSLog( @"[%@] EXIT -%@- %@", [[NSThread currentThread] valueForKey:@"seqNum"], [sender className], text );
}

@end
