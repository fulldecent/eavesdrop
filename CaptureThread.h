//
//  CaptureThread.h
//  Eavesdrop
//
//  Created by Eric Baur on 5/27/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "sniff.h"
#import <sys/time.h>

#import <pcap.h>
#import <pcap-namedb.h>

#import <BHLogger/BHLogging.h>
#import "DOHelpers.h"
#import "CaptureHandlers.h"

@interface CaptureThread : NSObject <CaptureThreadProtocol> {
	NSString *client;

	BOOL capturesPayload;
	NSString *saveFilename;
	NSString *readFilename;
	NSString *filter;
	BOOL promiscuous;
	NSString *interface;
	
	BOOL isActive;
	
	id queueProxy;
	
	void (*capture_callback)(u_char*,const struct pcap_pkthdr*,const u_char*);

	char errbuf[PCAP_ERRBUF_SIZE];  /* Error buffer */    
	bpf_u_int32 maskp;              /* subnet mask */
	bpf_u_int32 netp;               /* ip */
	struct bpf_program fp;
	pcap_t *captureHandle;

}

+ (id)sharedCollectorsDictionary;
+ (BOOL)setCollector:(id)collector withName:(NSString *)name;
+ (void)removeCollectorWithName:(NSString *)name;
+ (id)collectorWithName:(NSString *)name;

- (NSString *)client;
- (void)setClient:(NSString *)newClient;

- (NSString *)saveFile;
- (void)setSaveFile:(NSString *)saveFile;
- (NSString *)readFile;
- (void)setReadFile:(NSString *)readFile;

- (NSString *)captureFilter;
- (void)setCaptureFilter:(NSString *)filterString;

- (NSString *)interface;
- (void)setInterface:(NSString *)newInterface;

- (BOOL)promiscuous;
- (void)setPromiscuous:(BOOL)promiscuousMode;

- (BOOL)capturesPayload;
- (void)setCapturesPayload:(BOOL)shouldCapture;

- (BOOL)isActive;

void packetHandler( u_char* user, const struct pcap_pkthdr* header, const u_char* packet );

@end
