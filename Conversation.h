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

@property (NS_NONATOMIC_IOSONLY, readonly, strong) id myself;

- (instancetype)initWithOrderNumber:(int)number packet:(NSDictionary *)origPacket;
- (instancetype)initWithOrderingNumber:(int)number source:(NSString *)origSource		port:(int)sourcePort
									destination:(NSString *)origDestination port:(int)destinationPort
									flags:(NSString *)origFlags
									sequence:(unsigned long long)origSequence
									acknowledgment:(unsigned long long)origAcknowledgment
									window:(int)origWindow			length:(int)origLength
									timestamp:(double)origTimestamp		payload:(NSData *)origPayload NS_DESIGNATED_INITIALIZER;
									
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

@property (NS_NONATOMIC_IOSONLY, readonly) double lastTimestamp;
@property (NS_NONATOMIC_IOSONLY, readonly) double timelength;
@property (NS_NONATOMIC_IOSONLY, readonly) double starttime;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *source;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *destination;
@property (NS_NONATOMIC_IOSONLY) int sourcePort;
@property (NS_NONATOMIC_IOSONLY) int destinationPort;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSAttributedString *flagsAsAttributedString;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSAttributedString *sourceFlagsAsAttributedString;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSAttributedString *destinationFlagsAsAttributedString;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *payloadArrayBySource;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *payload;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *clientPayload;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *serverPayload;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSAttributedString *clientPayloadAsAttributedString;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSAttributedString *serverPayloadAsAttributedString;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSAttributedString *payloadAsAttributedString;
- (NSAttributedString *)_payloadAsAttributedStringForHost:(NSString *)sourceHost;
/// these four C functions are unused for now ///
int fill_ascii( unsigned char* buffer, int bufferLen, unsigned char* output );
int fill_hex( unsigned char* buffer, int bufferLen, unsigned char* output );
int fill_hex_ascii( unsigned char* buffer, int bufferLen, unsigned char* output );
int fill_count( unsigned char* buffer, int bufferLen, unsigned char* output );

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *clientPayloadAsRTFData;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *serverPayloadAsRTFData;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *payloadAsRTFData;
//- (NSArray *)htmlDictionaries;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *imageDictionaries;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *serverImageData;
- (NSData *)findImageDataInData:(NSData *)searchData;


@property (NS_NONATOMIC_IOSONLY, getter=isHidden) BOOL hidden;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *waitTimes;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *serverWaitTimes;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *clientWaitTimes;
@property (NS_NONATOMIC_IOSONLY, readonly) double maxWaitTime;
@property (NS_NONATOMIC_IOSONLY, readonly) double serverMaxWaitTime;
@property (NS_NONATOMIC_IOSONLY, readonly) double clientMaxWaitTime;
@property (NS_NONATOMIC_IOSONLY, readonly) double connectWaitTime;
@property (NS_NONATOMIC_IOSONLY, readonly) double bytesPerSecond;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *conversationID;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *history;
- (NSDictionary *)dictionaryForHistoryIndex:(int)index;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) DataSet *historyDataSet;
- (DataSet *)historyDataSetForHost:(NSString *)host;
- (DataSet *)dataSetWithKeys:(NSArray *)keys independent:(NSString *)indKey forHost:(NSString *)host;
- (NSDictionary *)dictionaryForHistoryDataSetIndex:(int)index;

@end
