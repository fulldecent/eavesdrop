//
//  Capture.h
//  Capture
//
//  Created by Eric Baur on Tue Jun 29 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

#import "sniff.h"
#import <sys/time.h>

#import <pcap.h>
#import <pcap-namedb.h>

//#import "Authorization.h"
#import "PacketHandler.h"
#import "CaptureHandler.h"

@interface Capture : NSObject <CaptureHandler>
{
	NSString *device;
	NSString *filter;
	NSString *captureID;
	
	NSString *outfile;
	NSString *infile;

	NSString *queueIdentifier;
	NSString *toolIdentifier;
	id queueProxy;
	NSTask *captureTask;
	
	BOOL active;
	BOOL promiscuous;
	BOOL capturePayload;
	
	BOOL keepAlive;

	void (*my_callback)(u_char*,const struct pcap_pkthdr*,const u_char*);

	char errbuf[PCAP_ERRBUF_SIZE];  /* Error buffer */    
	bpf_u_int32 maskp;              /* subnet mask */
	bpf_u_int32 netp;               /* ip */
	struct bpf_program fp;
	pcap_t *captureHandle;
}

+ (void)initialize;
+ (id)sharedControllersDictionary;
+ (BOOL)setController:(id)controller withName:(NSString *)name;
+ (void)removeControllerWithName:(NSString *)name;
+ (id)controllerWithName:(NSString *)name;

+ (NSArray *)interfaces;

- (instancetype)initWithServerIdentifier:(NSString *)serverIdent clientIdentifier:(NSString *)clientIdent NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithServerIdentifier:(NSString *)serverIdent clientIdentifier:(NSString *)clientIdent
						device:(NSString *)usingDevice filter:(NSString *)usingFilter
						promiscuous:(BOOL)usingPromiscuous NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithServerIdentifier:(NSString *)serverIdent clientIdentifier:(NSString *)clientIdent
						file:(NSString *)usingFile filter:(NSString *)usingFilter
						promiscuous:(BOOL)usingPromiscuous NS_DESIGNATED_INITIALIZER;

- (void)setKeepAlive;
- (void)unsetKeepAlive;
- (void)checkKeepAlive;

/// see CaptureHandler.h for most methods ///

void packetHandler( u_char* user, const struct pcap_pkthdr* header, const u_char* packet );

@end
