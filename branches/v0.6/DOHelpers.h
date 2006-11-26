//
//  DOHelpers.h
//  Eavesdrop
//
//  Created by Eric Baur on 5/21/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <BHLogger/BHLogging.h>

@interface DOHelpers : NSObject {

}

+ (BOOL)vendObject:(id)object withName:(NSString *)name local:(BOOL)local;
+ (id)getProxyWithName:(NSString *)name protocol:(Protocol *)protocol host:(NSString *)remoteHost;

@end
