//
//  Conversation.h
//  Capture
//
//  Created by Eric Baur on Thu Jul 08 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

#define CONVERSATION_ASCII		0
#define CONVERSATION_HEX		1
#define CONVERSATION_HEX_ASCII	2

#import <Foundation/Foundation.h>

#import "sniff.h"
#import <pcap.h>
#import <pcap-namedb.h>

#import "DataSet.h"
#import "ColorizationRules.h"

@interface Conversation : NSObject {
	int ordering_number;
	NSString *conversationID;
	BOOL idChanged;
	BOOL hidden;
	int representation;
	BOOL displayCount;

	NSString *source;
	NSString *destination;
	int sport;
	int dport;
	
	int bytes, sbytes, dbytes;
	int count, scount, dcount;
	
	unsigned int sequence, acknowledgement;
	int window;

	NSString *flags;
	NSString *sflags;
	NSString *dflags;
	double timestamp;
	
	NSMutableArray *flagsArray;
	NSMutableArray *sequenceArray;
	NSMutableArray *acknowledgementArray;
	NSMutableArray *windowArray;
	NSMutableArray *lengthArray;
	NSMutableArray *timestampArray;
	NSMutableArray *payloadArray;
	
	ColorizationRules *colorizationRules;
	
	NSArrayController *historyController;
}

+ (BOOL)requiresSyn;
+ (void)setRequiresSyn:(BOOL)synFirst;

+ (BOOL)capturesData;
+ (void)setCapturesData:(BOOL)dataCapture;

+ (NSString *)calculateIDFromSource:(NSString *)src port:(int)srcp destination:(NSString *)dst port:(int)dstp;

+ (id)blankConversation;

- (id)myself;

- (id)initWithOrderNumber:(int)number packet:(NSDictionary *)origPacket;
- (id)initWithOrderingNumber:(int)number source:(NSString *)origSource		port:(int)sourcePort
									destination:(NSString *)origDestination port:(int)destinationPort
									flags:(NSString *)origFlags
									sequence:(unsigned long long)origSequence
									acknowledgment:(unsigned long long)origAcknowledgment
									window:(int)origWindow			length:(int)origLength
									timestamp:(double)origTimestamp		payload:(NSData *)origPayload;
									
- (void)addPacket:(NSDictionary *)newPacket;
- (void)addPacketWithSource:(NSString *)packetSource flags:(NSString *)packetFlags
	sequence:(unsigned long long)packetSeq acknowledgement:(unsigned long long)packetAck window:(int)packetWindow
	length:(int)packetLength timestamp:(double)packetTimestamp payload:(NSData *)packetPayload;
- (void)addFlags:(NSString *)newFlags withSource:(NSString *)theSource;
- (void)addSequence:(NSNumber *)newSequence;
- (void)addSequenceAsULL:(unsigned long long)newSequence;
- (void)addAcknowledgement:(NSNumber *)newAcknowledgement;
- (void)addAcknowledgementAsULL:(unsigned long long)newAcknowledgement;
- (void)addWindow:(NSNumber *)newWindow;
- (void)addWindowAsInt:(int)newWindow;
- (void)addLength:(NSNumber *)newLength;
- (void)addLengthAsInt:(int)newLength;
- (void)addTimestampAsDouble:(double)newTimestamp;
- (void)addPayload:(NSData *)newPayload withSource:(NSString *)theSource;

- (double)lastTimestamp;
- (double)timelength;
- (double)starttime;
- (NSString *)source;
- (NSString *)destination;
- (int)sourcePort;
- (int)destinationPort;

- (NSAttributedString *)flagsAsAttributedString;
- (NSAttributedString *)sourceFlagsAsAttributedString;
- (NSAttributedString *)destinationFlagsAsAttributedString;

- (NSArray *)payloadArrayBySource;
- (NSData *)payload;
- (NSData *)clientPayload;
- (NSData *)serverPayload;

- (NSAttributedString *)clientPayloadAsAttributedString;
- (NSAttributedString *)serverPayloadAsAttributedString;
- (NSAttributedString *)payloadAsAttributedString;
- (NSAttributedString *)_payloadAsAttributedStringForHost:(NSString *)sourceHost;
/// these four C functions are unused for now ///
int fill_ascii( unsigned char* buffer, int bufferLen, unsigned char* output );
int fill_hex( unsigned char* buffer, int bufferLen, unsigned char* output );
int fill_hex_ascii( unsigned char* buffer, int bufferLen, unsigned char* output );
int fill_count( unsigned char* buffer, int bufferLen, unsigned char* output );

- (NSData *)clientPayloadAsRTFData;
- (NSData *)serverPayloadAsRTFData;
- (NSData *)payloadAsRTFData;
//- (NSArray *)htmlDictionaries;
- (NSArray *)imageDictionaries;
- (NSData *)serverImageData;
- (NSData *)findImageDataInData:(NSData *)searchData;

- (void)setSource:(NSString *)newSource;
- (void)setDestination:(NSString *)newDestination;
- (void)setSourcePort:(int)newSourcePort;
- (void)setDestinationPort:(int)newDestinationPort;

- (BOOL)isHidden;
- (void)setHidden:(BOOL)state;

- (NSArray *)waitTimes;
- (NSArray *)serverWaitTimes;
- (NSArray *)clientWaitTimes;
- (double)maxWaitTime;
- (double)serverMaxWaitTime;
- (double)clientMaxWaitTime;
- (double)connectWaitTime;
- (double)bytesPerSecond;

- (NSString *)conversationID;
- (NSArray *)history;
- (NSDictionary *)dictionaryForHistoryIndex:(int)index;
- (DataSet *)historyDataSet;
- (DataSet *)historyDataSetForHost:(NSString *)host;
- (DataSet *)dataSetWithKeys:(NSArray *)keys independent:(NSString *)indKey forHost:(NSString *)host;
- (NSDictionary *)dictionaryForHistoryDataSetIndex:(int)index;

@end
