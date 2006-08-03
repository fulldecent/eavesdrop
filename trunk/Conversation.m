//
//  Conversation.m
//
//  Created by Eric Baur on Thu Jul 08 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

#import "Conversation.h"

@implementation Conversation

static BOOL requireSyn;
static BOOL capturesData;

+ (void)initialize
{

	// update flags
	[self setKeys:[NSArray arrayWithObject:@"flags"]
		triggerChangeNotificationsForDependentKey:@"flagsArray"];
	[self setKeys:[NSArray arrayWithObject:@"flags"]
		triggerChangeNotificationsForDependentKey:@"flagsAsAttributedString"];
	[self setKeys:[NSArray arrayWithObject:@"sflags"]
		triggerChangeNotificationsForDependentKey:@"sourceFlagsAsAttributedString"];
	[self setKeys:[NSArray arrayWithObject:@"dflags"]
		triggerChangeNotificationsForDependentKey:@"destinationFlagsAsAttributedString"];
	
	// update sequence numbers
	[self setKeys:[NSArray arrayWithObject:@"seq"]
		triggerChangeNotificationsForDependentKey:@"sequenceArray"];
	// update acknowledgements
	[self setKeys:[NSArray arrayWithObject:@"ack"]
		triggerChangeNotificationsForDependentKey:@"acknowledgementArray"];
	// update windows
	[self setKeys:[NSArray arrayWithObject:@"win"]
		triggerChangeNotificationsForDependentKey:@"windowArray"];
		
	// update length
	[self setKeys:[NSArray arrayWithObject:@"bytes"]
		triggerChangeNotificationsForDependentKey:@"lengthArray"];
	
	// update timestamp
	[self setKeys:[NSArray arrayWithObject:@"timestamp"]
		triggerChangeNotificationsForDependentKey:@"timestampArray"];
	
	//update payload
	[self setKeys:[NSArray arrayWithObjects:@"payloadArray", @"representation", @"displayCount", @"bytes", nil]
		triggerChangeNotificationsForDependentKey:@"payloadAsAttributedString"];
	[self setKeys:[NSArray arrayWithObjects:@"representation", @"sbytes", nil]
		triggerChangeNotificationsForDependentKey:@"clientPayloadAsAttributedString"];
	[self setKeys:[NSArray arrayWithObjects:@"representation", @"dbytes", nil]
		triggerChangeNotificationsForDependentKey:@"serverPayloadAsAttributedString"];

	// not sure if @"representation" needs to be here...
	[self setKeys:[NSArray arrayWithObjects:@"representation", @"displayCount", @"clientPayloadAsAttributedString", nil]
		triggerChangeNotificationsForDependentKey:@"clientPayloadAsRTFData"];
	[self setKeys:[NSArray arrayWithObjects:@"representation", @"serverPayloadAsAttributedString", nil]
		triggerChangeNotificationsForDependentKey:@"serverPayloadAsRTFData"];
	[self setKeys:[NSArray arrayWithObjects:@"representation", @"payloadAsAttributedString", nil]
		triggerChangeNotificationsForDependentKey:@"payloadAsRTFData"];
	
	[self setKeys:[NSArray arrayWithObjects:
			@"flagsArray", @"sequenceArray", @"acknowledgementArray",
			@"windowArray", @"lengthArray", @"timestampArray", nil
		]
		triggerChangeNotificationsForDependentKey:@"history"];
	[self setKeys:[NSArray arrayWithObjects:
			@"flagsArray", @"sequenceArray", @"acknowledgementArray",
			@"windowArray", @"lengthArray", @"timestampArray", nil
		]
		triggerChangeNotificationsForDependentKey:@"historyDataSet"];
	[self setKeys:[NSArray arrayWithObjects:
			@"flagsArray", @"sequenceArray", @"acknowledgementArray",
			@"windowArray", @"lengthArray", @"timestampArray", nil
		]
		triggerChangeNotificationsForDependentKey:@"myself"];
		
	[ColorizationRules sharedRulesWithDictionary:[[NSDictionary alloc] initWithObjectsAndKeys:
			[NSColor greenColor],   @"-S------",
			[NSColor yellowColor],  @"-S--A---",
			[NSColor brownColor],	@"----A---",
			[NSColor blueColor],	@"---PA---",
			[NSColor blackColor],   @"F---A---",
			[NSColor blackColor],   @"F-------",
			[NSColor magentaColor],	@"--R-A---",
			[NSColor redColor],		@"--R-----",
			[NSColor grayColor],	@"--------",
			nil
		]
	];
	
	requireSyn = NO;
}

+ (BOOL)requiresSyn
{
	return requireSyn;
}

+ (void)setRequiresSyn:(BOOL)synFirst
{
	requireSyn = synFirst;
}

+ (BOOL)capturesData
{
	return capturesData;
}

+ (void)setCapturesData:(BOOL)dataCapture
{
	capturesData = dataCapture;
}

+ (NSString *)calculateIDFromSource:(NSString *)src port:(int)srcp destination:(NSString *)dst port:(int)dstp
{
	if (srcp>dstp) {
		return [NSString stringWithFormat:@"%@:%d-%@:%d",
			src, srcp, dst, dstp
		];
	} else {
		return [NSString stringWithFormat:@"%@:%d-%@:%d",
			dst, dstp, src, srcp
		];
	}
}

+ (id)blankConversation
{
	return [[[Conversation alloc]
			initWithOrderingNumber:0
			source:@"127.0.0.1"				port:0
			destination:@"255.255.255.255"	port:65535
			flags:@"--------"				
			sequence:0	acknowledgment:0	window:0
			length:0	timestamp:0.0		payload:[NSData data]
		] autorelease
	];
}

#pragma mark "Global" methods

- (id)myself
{
	return self;
}

- (id)initWithOrderNumber:(int)number packet:(NSDictionary *)origPacket
{
	return [self
		initWithOrderingNumber:number
		source:			[origPacket objectForKey:@"source"]
		port:			[[origPacket objectForKey:@"sport"] intValue]
		destination:	[origPacket objectForKey:@"destination"]
		port:			[[origPacket objectForKey:@"dport"] intValue]
		flags:			[origPacket objectForKey:@"flags"]
		sequence:		[[origPacket objectForKey:@"sequence"] unsignedLongLongValue]
		acknowledgment:	[[origPacket objectForKey:@"acknowledgement"] unsignedLongLongValue]
		window:			[[origPacket objectForKey:@"window"] intValue]
		length:			[[origPacket objectForKey:@"length"] intValue]
		timestamp:		[[origPacket objectForKey:@"timestamp"] doubleValue]
		payload:		[origPacket objectForKey:@"payload"]
	];
}

- (id)initWithOrderingNumber:(int)number source:(NSString *)origSource		port:(int)sourcePort
									destination:(NSString *)origDestination port:(int)destinationPort
									flags:(NSString *)origFlags
									sequence:(unsigned long long)origSequence
									acknowledgment:(unsigned long long)origAcknowledgment
									window:(int)origWindow			length:(int)origLength
									timestamp:(double)origTimestamp		payload:(NSData *)origPayload
{
//	if (requireSyn && ![origFlags isEqual:@"-S------"])
//		return nil;
	
	self = [super init];
	if (self) {
		ordering_number = number;
		[self setSource:origSource];
		[self setSourcePort:sourcePort];
		[self setDestination:origDestination];
		[self setDestinationPort:destinationPort];
		
		if (requireSyn && ![origFlags isEqual:@"-S------"])
			hidden = YES;
		else
			hidden = NO;
		
		representation = 0;
		
		bytes = 0;
		sbytes = 0;
		dbytes = 0;
		
		count = 1;
		scount = 1;
		dcount = 0;
		
		flagsArray = [[NSMutableArray array] retain];
		[self addFlags:origFlags withSource:origSource];
		
		sequenceArray = [[NSMutableArray array] retain];
		[self addSequenceAsULL:origSequence];
		
		acknowledgementArray = [[NSMutableArray array] retain];
		[self addAcknowledgementAsULL:origAcknowledgment];
		
		windowArray = [[NSMutableArray array] retain];
		[self addWindowAsInt:origWindow];
		
		lengthArray = [[NSMutableArray array] retain];
		[self addLengthAsInt:origLength];
		
		timestampArray = [[NSMutableArray array] retain];
		[self addTimestampAsDouble:origTimestamp];
		
		sflags = origFlags;
		[sflags retain];
		dflags = [NSString stringWithString:@"--------"];
		[dflags retain];
		flags = origFlags;
		[flags retain];
		timestamp = origTimestamp;

		if (capturesData)
			payloadArray = [[NSMutableArray array] retain];
		else
			payloadArray = nil;
			
		[self addPayload:origPayload withSource:source];

		colorizationRules = [[ColorizationRules sharedRules] retain];
	}
	return self;
}									

- (void)addPacket:(NSDictionary *)newPacket
{
	[self addPacketWithSource:	[newPacket objectForKey:@"source"]
		flags:					[newPacket objectForKey:@"flags"]
		sequence:				[[newPacket objectForKey:@"sequence"] unsignedLongLongValue]
		acknowledgement:		[[newPacket objectForKey:@"acknowledgement"] unsignedLongLongValue]
		window:					[[newPacket objectForKey:@"window"] intValue]
		length:					[[newPacket objectForKey:@"length"] intValue]
		timestamp:				[[newPacket objectForKey:@"timestamp"] doubleValue]
		payload:				[newPacket objectForKey:@"payload"]
	];
}

- (void)addPacketWithSource:(NSString *)packetSource flags:(NSString *)packetFlags
	sequence:(unsigned long long)packetSeq acknowledgement:(unsigned long long)packetAck window:(int)packetWindow
	length:(int)packetLength timestamp:(double)packetTimestamp payload:(NSData *)packetPayload
{
	[self addFlags:packetFlags withSource:packetSource];
	[self addSequenceAsULL:packetSeq];
	[self addAcknowledgementAsULL:packetAck];
	[self addWindowAsInt:packetWindow];
	[self addLengthAsInt:packetLength];
	[self addTimestampAsDouble:packetTimestamp];
	[self addPayload:packetPayload withSource:packetSource];
	
	if ([packetSource isEqual:source]) {
		scount++;
		sbytes += packetLength;
	} else if ([packetSource isEqual:destination]) {
		dcount++;
		dbytes += packetLength;
	}
	
	count++;
	bytes += packetLength;
	
	if (historyController)
		[historyController addObject:[self dictionaryForHistoryIndex:(count-1)] ];
}

#pragma mark simple accessor methods

- (void)addFlags:(NSString *)newFlags withSource:(NSString *)theSource
{
	[flags release];
	if ([theSource isEqual:source]) {
		flags = [NSString stringWithFormat:@" %@>",newFlags];
		[sflags release];
		sflags = newFlags;
		[sflags retain];
	} else if ([theSource isEqual:destination]) {
		flags = [NSString stringWithFormat:@"<%@ ",newFlags];
		[dflags release];
		dflags = newFlags;
		[dflags retain];
	} else {
		flags = @"-xxxxxxxx-";
	}
	[flagsArray addObject:flags];
	[flags retain];
}

- (void)addSequence:(NSNumber *)newSequence
{
	sequence = [newSequence unsignedLongLongValue];
	[sequenceArray addObject:newSequence];
}

- (void)addSequenceAsULL:(unsigned long long)newSequence
{
	sequence = newSequence;
	[sequenceArray addObject:[NSNumber numberWithUnsignedLongLong:sequence]];
}

- (void)addAcknowledgement:(NSNumber *)newAcknowledgement
{
	acknowledgement = [newAcknowledgement unsignedLongLongValue];
	[acknowledgementArray addObject:newAcknowledgement];
}

- (void)addAcknowledgementAsULL:(unsigned long long)newAcknowledgement
{
	acknowledgement = newAcknowledgement;
	[acknowledgementArray addObject:[NSNumber numberWithUnsignedLongLong:acknowledgement]];
}

- (void)addWindow:(NSNumber *)newWindow
{
	window = [newWindow intValue];
	[windowArray addObject:newWindow];
}

- (void)addWindowAsInt:(int)newWindow
{
	window = newWindow;
	[windowArray addObject:[NSNumber numberWithInt:window]];
}

- (void)addLength:(NSNumber *)newLength
{
	[lengthArray addObject:newLength];
}

- (void)addLengthAsInt:(int)newLength
{
	[lengthArray addObject:[NSNumber numberWithInt:newLength] ];
}

- (void)addTimestampAsDouble:(double)newTimestamp
{
	if (newTimestamp)
		[timestampArray addObject:[NSDate dateWithTimeIntervalSince1970:newTimestamp] ];
	else
		[timestampArray addObject:[NSDate dateWithTimeIntervalSinceNow:0]];
		
	timestamp = newTimestamp;
}

- (void)addPayload:(NSData *)newPayload withSource:(NSString *)theSource
{
	if ( ! capturesData ) {
		return;
	}
	//NSLog(@"addPayload:%@ withSource:%@",[newPayload description],theSource);
	[payloadArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			newPayload,		@"payload",
			theSource,		@"source",
			nil
		]
	];
}

- (double)lastTimestamp
{
	return timestamp;
}

- (double)timelength
{
	return (timestamp - [[timestampArray objectAtIndex:0] timeIntervalSince1970]);
}

- (double)starttime
{
	return [[timestampArray objectAtIndex:0] timeIntervalSince1970];
}

- (NSString *)source
{
	return source;
}

- (NSString *)destination
{
	return destination;
}

- (int)sourcePort
{
	return sport;
}

- (int)destinationPort
{
	return dport;
}

#pragma mark complex accessor methods

- (NSAttributedString *)flagsAsAttributedString
{
	return [colorizationRules colorize:flags];
}

- (NSAttributedString *)sourceFlagsAsAttributedString
{
	return [colorizationRules colorize:sflags];
}

- (NSAttributedString *)destinationFlagsAsAttributedString
{
	return [colorizationRules colorize:dflags];
}

- (NSArray *)payloadArrayBySource
{
	//NSEnumerator *en = [payloadArray objectEnumerator];
	NSDictionary *tempDict;
	NSData *testData;
	NSMutableData *tempData = nil;
	NSMutableArray *returnArray = [NSMutableArray array];
	unsigned int payloadCount = 0;
	unsigned int payloadBytes = 0;
	unsigned int payloadOrder = 0;
	int startingIndex = 0;

	id currentSource = nil;
	
	int i;
	int packetCount = [payloadArray count];
	for (i=0; i<packetCount; i++) {
	//while (tempDict = [en nextObject]) {
		tempDict = [payloadArray objectAtIndex:i];
		testData = [tempDict objectForKey:@"payload"];
		if ([testData length]) {
			if ([[tempDict objectForKey:@"source"] isEqual:currentSource]) {
				[tempData appendData:testData];
				payloadCount++;
				payloadBytes += [tempData length];
			} else {
				if (tempData ) {
					[returnArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							currentSource,  @"source",
							tempData,		@"payload",
							[NSNumber numberWithInt:payloadCount], @"packetCount",
							[NSNumber numberWithInt:payloadBytes], @"bytes",
							[NSNumber numberWithInt:payloadOrder], @"order",
							[NSNumber numberWithDouble:
								[[timestampArray objectAtIndex:i]
									timeIntervalSinceDate:[timestampArray objectAtIndex:startingIndex]
								]
							], @"timeDelta",
							nil
						]
					];
				}
				payloadOrder++;
				currentSource = [tempDict objectForKey:@"source"];
				tempData = [NSMutableData dataWithData:testData ];
				payloadCount = 1;
				payloadBytes = [tempData length];
				startingIndex = i;
			}
		}
	}
	//do it one more time (for the last bit to be caught)
	if (tempData ) {
		[returnArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				currentSource,  @"source",
				tempData,		@"payload",
				[NSNumber numberWithInt:payloadCount], @"packetCount",
				[NSNumber numberWithInt:payloadBytes], @"bytes",
				[NSNumber numberWithInt:payloadOrder], @"order",
				[NSNumber numberWithDouble:
					[[timestampArray objectAtIndex:i-1]
						timeIntervalSinceDate:[timestampArray objectAtIndex:startingIndex]
					]
				], @"timeDelta",
				nil
			]
		];
	}

	return [returnArray copy];
}

- (NSData *)payload
{
	NSEnumerator *en = [payloadArray objectEnumerator];
	NSDictionary *tempDict;
	NSMutableData *returnData = [NSMutableData data];

	while (tempDict = [en nextObject]) {
		[returnData appendData:[tempDict objectForKey:@"payload"] ];
	}
	return returnData;
}

- (NSData *)clientPayload
{
	NSEnumerator *en = [payloadArray objectEnumerator];
	NSDictionary *tempDict;
	NSMutableData *returnData = [NSMutableData data];

	while (tempDict = [en nextObject]) {
		if ([[tempDict objectForKey:@"source"] isEqual:source])
			[returnData appendData:[tempDict objectForKey:@"payload"] ];
	}
	return returnData;
}

- (NSData *)serverPayload
{
	NSEnumerator *en = [payloadArray objectEnumerator];
	NSDictionary *tempDict;
	NSMutableData *returnData = [NSMutableData data];

	while (tempDict = [en nextObject]) {
		if ([[tempDict objectForKey:@"source"] isEqual:destination])
			[returnData appendData:[tempDict objectForKey:@"payload"] ];
	}
	return returnData;
}

- (NSAttributedString *)clientPayloadAsAttributedString
{
	return [self _payloadAsAttributedStringForHost:source];
}

- (NSAttributedString *)serverPayloadAsAttributedString
{
	return [self _payloadAsAttributedStringForHost:destination];
}

- (NSAttributedString *)payloadAsAttributedString
{
	return [self _payloadAsAttributedStringForHost:nil];
}

- (NSAttributedString *)_payloadAsAttributedStringForHost:(NSString *)sourceHost
{
	ENTRY(NSLog(@"_payloadAsAttributedStringForHost: %@",sourceHost);)
	NSMutableAttributedString *tempString = [[[NSMutableAttributedString alloc] init] autorelease];
	NSEnumerator *en = [payloadArray objectEnumerator];
	NSDictionary *tempDict;
	NSData *tempData;
	NSColor *textColor;
	unsigned char *buffer;
	unsigned char *output;
	unsigned int bufferLen, outputLen;
	unsigned int i, j, k;
	unsigned char space = ' ';
	unsigned char newline = '\n';
	unsigned char vertbar = '|';
	unsigned char *hexDigits = "0123456789ABCDEF";

	
	while (tempDict = [en nextObject]) {
		if ([[tempDict objectForKey:@"source"] isEqual:source]) {
			textColor = [NSColor redColor];
		} else if ([[tempDict objectForKey:@"source"] isEqual:destination]) {
			textColor = [NSColor blueColor];
		} else {
			textColor = [NSColor grayColor];
		}
		if (sourceHost==nil || [[tempDict objectForKey:@"source"] isEqual:sourceHost]) {
			tempData = [tempDict objectForKey:@"payload"];
			bufferLen = [tempData length];
			buffer = malloc( bufferLen );	//need to make sure this was successful...

			[[tempDict objectForKey:@"payload"] getBytes:buffer];

			if (representation>2 || representation<0) {	//this line needs to change is more types are added
				NSLog( @"No valid representation specified: using CONVERSATION_ASCII" );
				representation = CONVERSATION_ASCII;
			}
			
	/* CONVERSATION_ASCII calculations */
			if (representation==CONVERSATION_ASCII) {
				ENTRY(NSLog( @"processing CONVERSATION_ASCII" );)
				outputLen = bufferLen;
				output = malloc( outputLen );

				for (i=0; i<bufferLen; i++) {
					if ( buffer[i] > 128 || buffer[i] < 32 ) {
						if ( !(buffer[i]==9 || buffer[i]==10 || buffer[i]==12 || buffer[i]==13 ) )
							output[i] = '.';
						else
							output[i] = buffer[i];
					} else {
						output[i] = buffer[i];
					}
				}
	/* CONVERSATION_HEX calculations */
			} else if (representation==CONVERSATION_HEX) {
				ENTRY(NSLog( @"processing CONVERSATION_HEX" );)
				outputLen = 51 * ( bufferLen/16 + 1 );
				output = malloc( outputLen );

				j = 0;	//index for output
				for (i=0; i<bufferLen && j<outputLen; i++) {
					if (i%16==0) {
						output[j++] = newline;	
					} else if (i%8==0) {
						output[j++] = space;
					}

					output[j++] = space;
					output[j++] = hexDigits[ (buffer[i]>>4) & 0xF ];
					output[j++] = hexDigits[ buffer[i] & 0xF ];
				}

				for ( ; j<outputLen; j++ )
					output[j] = space;

	/* CONVERSATION_HEX_ASCII calculations */
			} else if (representation==CONVERSATION_HEX_ASCII) {
				ENTRY(NSLog( @"processing CONVERSATION_HEX_ASCII" );)
				outputLen = 71 * ( bufferLen/16 + 1 );
				output = malloc( outputLen );

				j = 0;	//index for output
				for (i=0; i<bufferLen && j<outputLen; i++) {
					if (i%16==0) {
						if (i) {
							output[j++] = space;
							output[j++] = vertbar;
							for (k=i-16; k<i; k++) {
								if (k%8==0)
									output[j++] = space;
									
								if ( buffer[k] > 128 || buffer[k] < 32 )
									output[j++] = '.';
								else
									output[j++] = buffer[k];
							}
						}
						output[j++] = newline;	
					} else if (i%8==0) {
						output[j++] = space;
					}
					
					output[j++] = space;
					output[j++] = hexDigits[ (buffer[i]>>4) & 0xF ];
					output[j++] = hexDigits[ buffer[i] & 0xF ];
				}
				
				//fill up the hex spaces
				unsigned int roundOff = 16*(i/16+1);
				// We don't add to much space if line if full (i%16==0)
				if (!(i%16==0)) {
					for (k=i; k<roundOff; k++) {
						output[j++] = space;
						output[j++] = space;
						output[j++] = space;
						if (k%8==0)
							output[j++] = space;
					}
				}
			
				if (i) {
					output[j++] = space;
					output[j++] = vertbar;
				}
				
				//fill the last few letters
				// We need to remove 16 when line is full or we forgot ASCII of full line but 16%16==0
				for (k=i-16+((16-(i%16))%16); k<i; k++) {
					if (k%8==0)
						output[j++] = space;
						
					if ( buffer[k] > 128 || buffer[k] < 32 )
						output[j++] = '.';
					else
						output[j++] = buffer[k];
				}
				output[j++] = newline;	
				
				for ( ; j<outputLen; j++ )
					output[j] = space;

	/* OTHER - bad configuration */
			} else {
				NSLog( @"No valid representation specified: we should never get here.  Bailing out." );
				return nil;
			}
			
			ENTRY(NSLog( @"\no:\t%d\nj:\t%d\n", outputLen, j );)
			NSData *tempData = [NSData dataWithBytes:output length:outputLen]; // or j
			[tempString 
				appendAttributedString:[[NSAttributedString alloc]
					initWithString:[[NSString alloc]
						initWithData:tempData
						encoding:NSASCIIStringEncoding
					]
					attributes:[NSDictionary dictionaryWithObjectsAndKeys:
						textColor, NSForegroundColorAttributeName,
						[NSFont fontWithName:@"Courier" size:12.0], NSFontAttributeName,
						nil
					]
				]
			];
			free( buffer );
			free( output );
		}
	}
	return [tempString copy];
}

int fill_ascii( unsigned char* buffer, int bufferLen, unsigned char* output )
{//buffer and bufferLen are set - need to fill output - need to return outputLen
	//THIS IS A STUB FUNCTION FOR NOW
	return 0;
}

int fill_hex( unsigned char* buffer, int bufferLen, unsigned char* output )
{//buffer and bufferLen are set - need to fill output - need to return outputLen
	//THIS IS A STUB FUNCTION FOR NOW
	return 0;
}

int fill_hex_ascii( unsigned char* buffer, int bufferLen, unsigned char* output )
{//buffer and bufferLen are set - need to fill output - need to return outputLen
	//THIS IS A STUB FUNCTION FOR NOW
	return 0;}

int fill_count( unsigned char* buffer, int bufferLen, unsigned char* output )
{//buffer and bufferLen are set - need to fill output - need to return outputLen
	//THIS IS A STUB FUNCTION FOR NOW
	return 0;
}

- (NSData *)clientPayloadAsRTFData
{
	NSAttributedString *tempString = [self clientPayloadAsAttributedString];
	return [tempString RTFFromRange:NSMakeRange(0,[tempString length]) documentAttributes:[NSDictionary dictionary] ];
}

- (NSData *)serverPayloadAsRTFData
{
	NSAttributedString *tempString = [self serverPayloadAsAttributedString];
	return [tempString RTFFromRange:NSMakeRange(0,[tempString length]) documentAttributes:[NSDictionary dictionary] ];
}

- (NSData *)payloadAsRTFData
{
	NSAttributedString *tempString = [self payloadAsAttributedString];
	return [tempString RTFFromRange:NSMakeRange(0,[tempString length]) documentAttributes:[NSDictionary dictionary] ];
}

// this is experimental (and not used yet)
/*
- (NSArray *)htmlDictionaries
{
	NSArray *payloadChunksArray = [self payloadArrayBySource];
	NSString *tempString = nil;
	NSEnumerator *en = [payloadChunksArray objectEnumerator];
	NSDictionary *tempDict;
	NSMutableArray *returnArray = [NSMutableArray array];
	
	while (tempDict = [en nextObject]) {
		tempString = [self findHTMLStringInString:[tempDict objectForKey:@"payload"]];
		if (tempString)
			[returnArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					tempString,							@"htmlData",
					[tempDict objectForKey:@"source"],  @"source",
					nil
				]
			];
	}
	return [returnArray copy];
}
*/
- (NSArray *)imageDictionaries
{
	NSArray *payloadChunksArray = [self payloadArrayBySource];
	NSData *tempData = nil;
	NSEnumerator *en = [payloadChunksArray objectEnumerator];
	NSDictionary *tempDict;
	NSMutableArray *returnArray = [NSMutableArray array];
	
	while (tempDict = [en nextObject]) {
		tempData = [self findImageDataInData:[tempDict objectForKey:@"payload"]];
		if (tempData)
			[returnArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					tempData,							@"imageData",
					[tempDict objectForKey:@"source"],  @"source",
					nil
				]
			];
	}
	return [returnArray copy];
}

- (NSData *)serverImageData
{
	return [self findImageDataInData:[self serverPayload] ];
}

- (NSData *)findImageDataInData:(NSData *)searchData
{
	unsigned char *aBuffer;
	unsigned len, i;
	int start,end;
	BOOL gif = NO;
	BOOL jpeg = NO;
	BOOL png = NO;
	
	len = [searchData length];
	aBuffer = malloc( len );
	[searchData getBytes:aBuffer];
	start = -1;
	end = 0;
	if (len>8) {	//this is an arbitrary restriction, do I need it?
		for (i=0; i<len-4; i++) {
			if ( aBuffer[i]=='G' && aBuffer[i+1]=='I' && aBuffer[i+2]=='F' && aBuffer[i+3]=='8' ) {
				start = i;
				gif = YES;
				break;
			}
			if (aBuffer[i]==0xFF && aBuffer[i+1]==0xD8 && aBuffer[i+2]==0xFF) {
				start = i;
				jpeg = YES;
				break;
			}
			if (aBuffer[i]==0x89 && aBuffer[i+1]=='P' && aBuffer[i+2]=='N' && aBuffer[i+3]=='G' && aBuffer[i+4]==0x0d && aBuffer[i+5]==0x0a && aBuffer[i+6]==0x1a && aBuffer[i+7]==0x0a) {
				start = i;
				png = YES;
				break;
			}
		}
	}
	if (gif && start<len) {
		for (i=start; i<len; i++) {
			if (aBuffer[i]==0x3B) {
				end = i;
				break;
			}
		}
	}
	if (jpeg && start<(len-1)) {
		for (i=start; i<len-1; i++) {
			if (aBuffer[i]==0xFF && aBuffer[i+1]==0xD9) {
				end = i+1;
				break;
			}
		}
	}
	if (png && start<(len-7)) {
		for (i=start; i<len-7; i++) {
			if (aBuffer[i]==0x49 && aBuffer[i+1]==0x45 && aBuffer[i+2]==0x4e && aBuffer[i+3]==0x44 && aBuffer[i+4]==0xae && aBuffer[i+5]==0x42 && aBuffer[i+6]==0x60 && aBuffer[i+7]==0x82) {
				end = i+7;
				break;
			}
		}
	}
	free( aBuffer );
	// I'm not using "end"... that may be bad (since the start condition can be matched other ways)
	// but, I may not have the end of the image (if it was not fully downloaded or the packet was lost) 
	if (start>=0)
		return [searchData subdataWithRange:NSMakeRange(start,len-start)];
	else
		return nil;
}

#pragma mark more accessor methods

- (void)setSource:(NSString *)newSource
{
	if (newSource==nil)
		return;
	[source release];
	source = newSource;
	[source retain];	
	idChanged = YES;
}

- (void)setDestination:(NSString *)newDestination
{
	if (newDestination==nil)
		return;
	[destination release];
	destination = newDestination;
	[destination retain];
	idChanged = YES;
}

- (void)setSourcePort:(int)newSourcePort
{
	if ( newSourcePort >= 0 && newSourcePort <= 65535 ) {
		sport = newSourcePort;
		idChanged = YES;
	}
}

- (void)setDestinationPort:(int)newDestinationPort
{
	if ( newDestinationPort >= 0 && newDestinationPort <= 65535 ) {
		dport = newDestinationPort;
		idChanged = YES;
	}
}

- (BOOL)isHidden
{
	//NSLog( @"check hidden state" );
	return hidden;
}

- (void)setHidden:(BOOL)state
{
	hidden = state;
}

#pragma mark intersting statistics

- (NSArray *)waitTimes
{
	NSMutableArray *tempArray = [NSMutableArray array];
	int i;
	int myCount = [timestampArray count];
	for (i=0; i<myCount; i++) {
		[tempArray addObject:[NSNumber
			numberWithDouble:[[timestampArray objectAtIndex:i] timeIntervalSince1970] - 
				[[timestampArray objectAtIndex:(i?i-1:0)] timeIntervalSince1970]
			]
		];
	}
	return [tempArray copy];
}

- (NSArray *)serverWaitTimes
{
	NSMutableArray *tempArray = [NSMutableArray array];
	int i;
	int myCount = [timestampArray count];
	for (i=0; i<myCount; i++) {
		if ( [[[payloadArray objectAtIndex:i] objectForKey:@"source"] isEqual:destination] ) {
			[tempArray addObject:[NSNumber
				numberWithDouble:[[timestampArray objectAtIndex:i] timeIntervalSince1970] - 
					[[timestampArray objectAtIndex:(i?i-1:0)] timeIntervalSince1970]
				]
			];
		}
	}
	return [tempArray copy];
}

- (NSArray *)clientWaitTimes
{
	NSMutableArray *tempArray = [NSMutableArray array];
	int i;
	int myCount = [timestampArray count];
	for (i=0; i<myCount; i++) {
		if ( [[[payloadArray objectAtIndex:i] objectForKey:@"source"] isEqual:source] ) {
			[tempArray addObject:[NSNumber
				numberWithDouble:[[timestampArray objectAtIndex:i] timeIntervalSince1970] - 
					[[timestampArray objectAtIndex:(i?i-1:0)] timeIntervalSince1970]
				]
			];
		}
	}
	return [tempArray copy];
}

- (double)maxWaitTime
{
	int i;
	double maxTime = -1;
	double tempTime;
	int myCount = [timestampArray count];
	for (i=0; i<myCount; i++) {
		tempTime = [[timestampArray objectAtIndex:i] timeIntervalSince1970] - 
			[[timestampArray objectAtIndex:(i?i-1:0)] timeIntervalSince1970];
		if (tempTime > maxTime)
			maxTime = tempTime;
	}
	return maxTime;
}

- (double)serverMaxWaitTime
{
	double maxTime = -1;
	double tempTime;
	int i;
	int myCount = [payloadArray count];
	for ( i=0; i<myCount; i++ ) {
		if ( [[[payloadArray objectAtIndex:i] objectForKey:@"source"] isEqual:destination] ) {
			tempTime = [[timestampArray objectAtIndex:i] timeIntervalSince1970] - 
				[[timestampArray objectAtIndex:(i?i-1:0)] timeIntervalSince1970];
			if (tempTime > maxTime)
				maxTime = tempTime;
		}
	}
	return maxTime;
}

- (double)clientMaxWaitTime
{
	double maxTime = -1;
	double tempTime;
	int i;
	int myCount = [payloadArray count];
	for ( i=0; i<myCount; i++ ) {
		if ( [[[payloadArray objectAtIndex:i] objectForKey:@"source"] isEqual:source] ) {
			tempTime = [[timestampArray objectAtIndex:i] timeIntervalSince1970] - 
				[[timestampArray objectAtIndex:(i?i-1:0)] timeIntervalSince1970];
			if (tempTime > maxTime)
				maxTime = tempTime;
		}
	}
	return maxTime;
}

- (double)connectWaitTime
{
	//bail if the first packet is not a SYN packet
	if ( ! [[flagsArray objectAtIndex:0] isEqualToString:@" -S------>"] ) {
		return 0;
	}
	//check the next few packets to see if any is a SYN/ACK
	int i;
	int myCount = [flagsArray count];
	for (i=1; i<6 && i<myCount; i++) {
		if ( [[flagsArray objectAtIndex:i] isEqualToString:@"<-S--A--- "] ) {
			return [[timestampArray objectAtIndex:i] timeIntervalSince1970] - 
				[[timestampArray objectAtIndex:0] timeIntervalSince1970];
		}
	}
	return 0;
}

- (double)bytesPerSecond
{
	return bytes / ( [[timestampArray objectAtIndex:[timestampArray count]-1] timeIntervalSince1970] - 
				[[timestampArray objectAtIndex:0] timeIntervalSince1970] );
}

#pragma mark meta-information

- (NSString *)conversationID
{
	if (idChanged)
		conversationID = [Conversation
			calculateIDFromSource:source
			port:sport
			destination:destination
			port:dport
		];
		
	return conversationID;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ (%d packets)",
		[self conversationID], count
	];
}

- (NSArray *)history
{
	int i=0;
	NSMutableArray *tempArray = [NSMutableArray array];
	
	for (i=0; i<count; i++) {
		[tempArray addObject:[self dictionaryForHistoryIndex:i] ];
	}
	return tempArray;
}

- (NSDictionary *)dictionaryForHistoryIndex:(int)index
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:index],				@"number",
		[flagsArray objectAtIndex:index],			@"flags",
		[sequenceArray objectAtIndex:index],		@"sequence",
		[acknowledgementArray objectAtIndex:index],	@"acknowledgement",
		[windowArray objectAtIndex:index],			@"window",
		[lengthArray objectAtIndex:index],			@"bytes",
		[NSNumber numberWithInt:
			[(NSData *)[[payloadArray objectAtIndex:index] objectForKey:@"payload"] length]
		], @"length",
		[timestampArray objectAtIndex:index],		@"timestamp",
		[NSNumber numberWithDouble:(
					[[timestampArray objectAtIndex:index] timeIntervalSince1970] - 
					[[timestampArray objectAtIndex:(index?index-1:0)] timeIntervalSince1970]
				)
		], @"delta",
		[colorizationRules colorize:[flagsArray objectAtIndex:index] ], @"colorFlags",
		nil
	];
}

- (DataSet *)historyDataSet
{
	return [self historyDataSetForHost:nil];
}

- (DataSet *)historyDataSetForHost:(NSString *)host
{
	int i=0;
	NSMutableArray *tempArray = [NSMutableArray array];
	
	for (i=0; i<count; i++) {
		// I might be able to set up a seperate array for the hosts... but I don't have to
		if ( host==nil || [[[payloadArray objectAtIndex:i] objectForKey:@"source"] isEqualToString:host] )
			[tempArray addObject:[self dictionaryForHistoryDataSetIndex:i] ];
	}
	DataSet *tempDataSet = [[[DataSet alloc] init] autorelease];
	[tempDataSet setData:tempArray];
	[tempDataSet setIndependentIdentifier:@"number"];
	[tempDataSet setCurrentIdentifier:@"bytes"];
	return tempDataSet;
}

- (DataSet *)dataSetWithKeys:(NSArray *)keys independent:(NSString *)indKey forHost:(NSString *)host
{
	/* MULTIPLE VALUES */
	BOOL useID =		[keys containsObject:@"id"]			|| [indKey isEqualToString:@"id"];
	BOOL useNum =		[keys containsObject:@"number"]		|| [indKey isEqualToString:@"number"];
	BOOL useTime =		[keys containsObject:@"starttime"]	|| [indKey isEqualToString:@"starttime"];
	BOOL useBytes =		[keys containsObject:@"bytes"]		|| [indKey isEqualToString:@"bytes"];
	BOOL useLen =		[keys containsObject:@"length"]		|| [indKey isEqualToString:@"length"];
	BOOL useWin =		[keys containsObject:@"window"]		|| [indKey isEqualToString:@"window"];
	BOOL useDelta =		[keys containsObject:@"delta"]		|| [indKey isEqualToString:@"delta"];
	BOOL useTimestamp =	[keys containsObject:@"timestamp"]	|| [indKey isEqualToString:@"timestamp"];
	BOOL useSource =	[keys containsObject:@"source"]		|| [indKey isEqualToString:@"source"];
	BOOL useFlagNums =	[keys containsObject:@"flagNums"]	|| [indKey isEqualToString:@"flagNums"];
	BOOL useWaitTimes = [keys containsObject:@"waittime"]	|| [indKey isEqualToString:@"waittime"];
	//BOOL useSeq = [keys containsObject:@"sequence"]		|| [indKey isEqualToString:@"sequence"];
	//BOOL useAck = [keys containsObject:@"acknowledgement"] || [indKey isEqualToString:@"acknowledgement"];
	BOOL multipleValues = useID||useNum||useTime||useBytes||useLen||useWin||useDelta
		||useTimestamp||useSource||useFlagNums||useWaitTimes;
		
	/* GLOBAL VALUES */
	BOOL useCount =		[keys containsObject:@"count"]				|| [indKey isEqualToString:@"count"];
	BOOL useTimeLen =	[keys containsObject:@"timelength"]			|| [indKey isEqualToString:@"timelength"];
	BOOL useConvID =	[keys containsObject:@"ordering_number"]	|| [indKey isEqualToString:@"ordering_number"];
	BOOL useMaxWait =	[keys containsObject:@"maxWaitTime"]		|| [indKey isEqualToString:@"maxWaitTime"];
	BOOL useConTime =	[keys containsObject:@"connectWaitTime"]	|| [indKey isEqualToString:@"connectWaitTime"];
	BOOL useServerMax = [keys containsObject:@"serverMaxWaitTime"]	|| [indKey isEqualToString:@"serverMaxWaitTime"];
	BOOL useClientMax = [keys containsObject:@"clientMaxWaitTime"]	|| [indKey isEqualToString:@"clientMaxWaitTime"];
	BOOL useDestPort =	[keys containsObject:@"destinationPort"]	|| [indKey isEqualToString:@"destinationPort"];
	BOOL useSrcPort =	[keys containsObject:@"sourcePort"]			|| [indKey isEqualToString:@"sourcePort"];
	BOOL useBPS =		[keys containsObject:@"bytesPerSecond"]		|| [indKey isEqualToString:@"bytesPerSecond"];
	//BOOL useWaitTimes =	[keys containsObject:@"waitTimes"]			|| [indKey isEqualToString:@"waitTimes"];
	//BOOL useServerWait =[keys containsObject:@"serverWaitTimes"]	|| [indKey isEqualToString:@"serverWaitTimes"];
	//BOOL useClientWait =[keys containsObject:@"clientWaitTimes"]	|| [indKey isEqualToString:@"clientWaitTimes"];
	
	int globalValues = useMaxWait + useConTime + useServerMax + useClientMax + useDestPort + useSrcPort
		+ useBPS + useConvID;
	
	NSMutableDictionary *tempDict;
	NSMutableArray *tempArray = [NSMutableArray array];
	
	int i,j;
	j = 0;
	int loopCount = 1;
	if (multipleValues)
		loopCount = count;
		
	for (i=0; i<loopCount; i++) {
		if ( host==nil || [[[payloadArray objectAtIndex:i] objectForKey:@"source"] isEqualToString:host] ) {
			tempDict = [NSMutableDictionary dictionary];
			if (useID)
				[tempDict setObject:[NSNumber numberWithInt:i] forKey:@"id"];
			if (useNum)
				[tempDict setObject:[NSNumber numberWithInt:j++] forKey:@"number"];
			if (useWin)
				[tempDict setObject:[windowArray objectAtIndex:i] forKey:@"window"];
			if (useBytes)
				[tempDict setObject:[lengthArray objectAtIndex:i] forKey:@"bytes"];
			if (useLen)
				[tempDict setObject:[NSNumber numberWithInt:
					[(NSData *)[[payloadArray objectAtIndex:i]
						objectForKey:@"payload"] length]
				] forKey:@"length"];
			if (useTime)
				[tempDict setObject:[NSNumber numberWithDouble:(
					[[timestampArray objectAtIndex:i] timeIntervalSince1970] - 
					[[timestampArray objectAtIndex:0] timeIntervalSince1970]
				)] forKey:@"starttime" ];
			if (useDelta)
				[tempDict setObject:[NSNumber numberWithDouble:(
					[[timestampArray objectAtIndex:i] timeIntervalSince1970] - 
					[[timestampArray objectAtIndex:(i?i-1:0)] timeIntervalSince1970]
				)] forKey:@"delta" ];
			if (useTimestamp)
				[tempDict setObject:[NSNumber numberWithDouble:
					[[timestampArray objectAtIndex:i] timeIntervalSince1970]
				] forKey:@"timestamp" ];
			if (useSource) {
				if ( [[[payloadArray objectAtIndex:i] objectForKey:@"source"] isEqualToString:[self source] ] )
					[tempDict setObject:[NSNumber numberWithInt:1] forKey:@"source"];
				else if ( [[[payloadArray objectAtIndex:i] objectForKey:@"source"] isEqualToString:[self destination] ] )
					[tempDict setObject:[NSNumber numberWithInt:-1] forKey:@"source"];				
				else
					[tempDict setObject:[NSNumber numberWithInt:0] forKey:@"source"];
			}
			if (useWaitTimes)
				[tempDict setObject:[NSNumber
					numberWithDouble:[[timestampArray objectAtIndex:i] timeIntervalSince1970] - 
						[[timestampArray objectAtIndex:(i?i-1:0)] timeIntervalSince1970]
					] forKey:@"waittime"
				];

			if (useFlagNums) {
				NSString *tempString = [flagsArray objectAtIndex:i];
				if ( [tempString isEqualToString:@"<-S------ "] || [tempString isEqualToString:@" -S------>"] ) {
					[tempDict setObject:[NSNumber numberWithInt:0] forKey:@"flagNums"];
				} else if ( [tempString isEqualToString:@"<-S--A--- "] || [tempString isEqualToString:@" -S--A--->"] ) {
					[tempDict setObject:[NSNumber numberWithInt:1] forKey:@"flagNums"];
				} else if ( [tempString isEqualToString:@"<----A--- "] || [tempString isEqualToString:@" ----A--->"] ) {
					[tempDict setObject:[NSNumber numberWithInt:2] forKey:@"flagNums"];
				} else if ( [tempString isEqualToString:@"<---PA--- "] || [tempString isEqualToString:@" ---PA--->"] ) {
					[tempDict setObject:[NSNumber numberWithInt:3] forKey:@"flagNums"];
				} else if ( [tempString isEqualToString:@"<F---A--- "] || [tempString isEqualToString:@" F---A--->"] ) {
					[tempDict setObject:[NSNumber numberWithInt:4] forKey:@"flagNums"];
				} else if ( [tempString isEqualToString:@"<F------- "] || [tempString isEqualToString:@" F------->"] ) {
					[tempDict setObject:[NSNumber numberWithInt:5] forKey:@"flagNums"];
				} else if ( [tempString isEqualToString:@"<--R-A--- "] || [tempString isEqualToString:@" --R-A--->"] ) {
					[tempDict setObject:[NSNumber numberWithInt:6] forKey:@"flagNums"];
				} else if ( [tempString isEqualToString:@"<--R----- "] || [tempString isEqualToString:@" --R----->"] ) {
					[tempDict setObject:[NSNumber numberWithInt:7] forKey:@"flagNums"];
				} else if ( [tempString isEqualToString:@"<-------- "] || [tempString isEqualToString:@" -------->"] ) {
					[tempDict setObject:[NSNumber numberWithInt:8] forKey:@"flagNums"];
				} else {	//will get here with uncommon flag combinations
					[tempDict setObject:[NSNumber numberWithInt:-1] forKey:@"flagNums"];
				}
			}
			int gvCounter;
			for (gvCounter=0; gvCounter<globalValues; gvCounter++) {
				if (useCount)
					[tempDict setObject:[self valueForKey:@"count"]				forKey:@"count"];
				if (useTimeLen)
					[tempDict setObject:[self valueForKey:@"timelength"]		forKey:@"timelength"];
				if (useConvID)
					[tempDict setObject:[self valueForKey:@"ordering_number"]	forKey:@"ordering_number"];
				if (useMaxWait)
					[tempDict setObject:[self valueForKey:@"maxWaitTime"]		forKey:@"maxWaitTime"];
				if (useConTime)
					[tempDict setObject:[self valueForKey:@"connectWaitTime"]	forKey:@"connectWaitTime"];
				if (useServerMax)
					[tempDict setObject:[self valueForKey:@"serverMaxWaitTime"]	forKey:@"serverMaxWaitTime"];
				if (useClientMax)
					[tempDict setObject:[self valueForKey:@"clientMaxWaitTime"]	forKey:@"clientMaxWaitTime"];
				if (useDestPort)
					[tempDict setObject:[self valueForKey:@"destinationPort"]	forKey:@"destinationPort"];
				if (useSrcPort)
					[tempDict setObject:[self valueForKey:@"sourcePort"]		forKey:@"sourcePort"];
				if (useBPS)
					[tempDict setObject:[self valueForKey:@"bytesPerSecond"]	forKey:@"bytesPerSecond"];
				//if (useWaitTimes)
				//	[tempDict setObject:[self valueForKey:@"waitTimes"]			forKey:@"waitTimes"];
				//if (useServerWait)
				//	[tempDict setObject:[self valueForKey:@"serverWaitTimes"]	forKey:@"serverWaitTimes"];
				//if (useClientWait)
				//	[tempDict setObject:[self valueForKey:@"clientWaitTimes"]	forKey:@"clientWaitTimes"];
	
			}

			[tempArray addObject:[tempDict copy]];
		}
	}

	DataSet *tempDataSet = [[[DataSet alloc] init] autorelease];
	[tempDataSet setData:tempArray];

	[tempDataSet setIndependentIdentifier:indKey];
	[tempDataSet setCurrentIdentifier:[keys objectAtIndex:0] ];

	return tempDataSet;
}

- (NSDictionary *)dictionaryForHistoryDataSetIndex:(int)index
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:index],				@"id",
		[NSNumber numberWithInt:index],				@"number",
		[sequenceArray objectAtIndex:index],		@"sequence",
		[acknowledgementArray objectAtIndex:index],	@"acknowledgement",
		[windowArray objectAtIndex:index],			@"window",
		[lengthArray objectAtIndex:index],			@"size",
		[NSNumber numberWithInt:
			[(NSData *)[[payloadArray objectAtIndex:index] objectForKey:@"payload"] length]
		], @"length",
		[NSNumber numberWithDouble:(
			[[timestampArray objectAtIndex:index] timeIntervalSince1970] - 
			[[timestampArray objectAtIndex:0] timeIntervalSince1970]
		)], @"starttime",
		[NSNumber numberWithDouble:
			[[timestampArray objectAtIndex:index] timeIntervalSince1970]
		], @"timestamp",
		nil
	];
}

@end
