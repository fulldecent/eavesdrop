//
//  CaptureHandler.h
//  Eavesdrop
//
//  Created by Eric Baur on 5/17/06
//  Copyright (c) 2006 Eric Shore Baur. All rights reserved.
//

@protocol CaptureServer
#pragma mark -
#pragma mark General Properties

- (NSString *)identifier;
- (oneway void)setIdentifier:(NSString *)newIdentifier;

- (NSArray *)allowedHosts;
- (oneway void)setAllowedHosts:(NSArray *)hostsArray;

- (int)pollingInterval;
- (oneway void)setPollingInterval:(int)newInterval;

- (BOOL)hidesServerMessages;
- (oneway void)setHidesServerMessages:(BOOL)hideMessagesState;

- (NSArray *)interfaces;

#pragma mark -
#pragma mark Capture Properties

- (NSString *)parentHost;
- (oneway void)setParentHost:(NSString *)newParent;

- (NSArray *)clients;
- (NSArray *)captures;
- (oneway void)addCaptureForClient:(NSString *)newClient;
- (oneway void)removeCaptureForClient:(NSString *)oldClient;

- (NSString *)saveFileForClient:(NSString *)clientIdentifier;
- (oneway void)setSaveFile:(NSString *)saveFile forClient:(NSString *)clientIdentifier;
- (NSString *)readFileForClient:(NSString *)clientIdentifier;
- (oneway void)setReadFile:(NSString *)readFile forClient:(NSString *)clientIdentifier;

- (NSString *)captureFilterForClient:(NSString *)clientIdentifier;
- (oneway void)setCaptureFilter:(NSString *)filterString forClient:(NSString *)clientIdentifier;

- (NSString *)interfaceForClient:(NSString *)clientIdentifier;
- (oneway void)setInterface:(NSString *)newInterface forClient:(NSString *)clientIdentifier;

- (BOOL)promiscuousForClient:(NSString *)clientIdentifier;
- (void)setPromiscuous:(BOOL)promiscuousMode forClient:(NSString *)clientIdentifier;

- (BOOL)capturesPayloadForClient:(NSString *)clientIdentifier;
- (oneway void)setCapturesPayload:(BOOL)shouldCapture forClient:(NSString *)clientIdentifier;

- (BOOL)isActiveForClient:(NSString *)clientIdentifier;

#pragma mark -
#pragma mark Actions

- (oneway void)startCaptureForClient:(NSString *)clientIdentifier;
- (BOOL)startCaptureWithFilter:(NSString *)captureFilter
	promiscuous:(BOOL)capturePromiscuous
	onInterface:(NSString *)captureInterface
	forClient:(NSString *)clientIdentifier;

- (oneway void)stopCaptureForClient:(NSString *)clientIdentifier;

- (oneway void)killServer;

@end

#pragma mark -
#pragma mark

@protocol CaptureThreadProtocol

- (oneway void)savePackets:(NSArray *)packetsArray;
- (oneway void)startCapture;
- (oneway void)stopCapture;
- (oneway void)killCapture;

@end

#pragma mark -
#pragma mark

@protocol PacketQueue

- (oneway void)addPacket:(NSData *)packetData withHeader:(NSData *)headerData;
- (oneway void)stopCollecting;

@end