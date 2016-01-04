//
//  GraphController.h
//  Eavesdrop
//
//  Created by Eric Baur on 12/18/04.
//  Copyright 2004 Eric Shore Baur. All rights reserved.
//

typedef NS_ENUM(unsigned int, GCSourceType) {
	GCBothHostsTag,
	GCClientOnlyTag,
	GCServerOnlyTag,
	GCAllPacketsTag,
	GCAllwFlagsTag
};

typedef NS_ENUM(unsigned int, GCGraphType) {
	GCBarGraphType,
	GCLineGraphType,
	GCScatterPlotType
};

typedef NS_ENUM(unsigned int, GCVariableType) {
	GCPacketIDTag			=0,
	GCPacketNumberTag		=1,
	GCTimeTag				=2,
	GCTotalSizeTag			=3,
	GCPayloadLengthTag		=4,
	GCWindowTag				=5,
	GCDeltaTag				=6,
	GCFlagsTag				=7,
	GCPacketsTag			=8,
	GCTimeLengthTag			=9,
	GCConversationIDTag		=10,
	GCMaxWaitTimeTag		=11,
	GCConnectWaitTimeTag	=12,
	GCServerMaxWaitTimeTag	=13,
	GCClientMaxWaitTimeTag	=14,
	GCServerPortTag			=15,
	GCClientPortTag			=16,
	GCBytesPerSecondTag		=17,
	GCAllDeltasTag			=18,
	GCServerDeltasTag		=19,
	GCClientDeltasTag		=20
};

#define GCPacketIDIdentifier			@"id"
#define GCPacketNumberIdentifier		@"number"
#define	GCTimeIdentifier				@"starttime"
#define GCTotalSizeIdentifier			@"bytes"
#define GCPayloadLengthIdentifier		@"length"
#define GCWindowIdentifier				@"window"
#define GCDeltaIdentifier				@"delta"
#define GCPacketsIdentifier				@"count"
#define GCTimeLengthIdentifier			@"timelength"
#define GCConversationIDIdentifier		@"ordering_number"
#define GCMaxWaitTimeIdentifier			@"maxWaitTime"
#define GCConnectWaitTimeIdentifier		@"connectWaitTime"
#define GCServerMaxWaitTimeIdentifier	@"serverMaxWaitTime"
#define GCClientMaxWaitTimeIdentifier	@"clientMaxWaitTime"
#define GCServerPortIdentifier			@"destinationPort"
#define GCClientPortIdentifier			@"sourcePort"
#define GCBytesPerSecondIdentifier		@"bytesPerSecond"
#define GCAllDeltasIdentifier			@"waittime"
#define GCServerDeltasIdentifier		@"serverWaitTimes"
#define GCClientDeltasIdentifier		@"clientWaitTimes"

#define GCPacketIDString			@"Packet ID"
#define GCPacketNumberString		@"Packet Number"
#define	GCTimeString				@"Time (normalized)"
#define GCTotalSizeString			@"Total Size"
#define GCPayloadLengthString		@"Payload Length"
#define GCWindowString				@"Window"
#define GCDeltaString				@"Time (delta)"
#define GCPacketsString				@"# of Packets"
#define GCTimeLengthString			@"Time length"
#define GCConversationIDString		@"Conversation ID"
#define GCMaxWaitTimeString			@"Max. Wait Time"
#define GCConnectWaitTimeString		@"Connect Wait Time"
#define GCServerMaxWaitTimeString	@"Server Max. Wait Time"
#define GCClientMaxWaitTimeString	@"Client Max. Wait Time"
#define GCServerPortString			@"Server Port"
#define GCClientPortString			@"Client Port"
#define GCBytesPerSecondString		@"Bytes / Second"
#define GCAllDeltasString			@"All Wait Times"
#define GCServerDeltasString		@"Server Wait Times"
#define GCClientDeltasString		@"Client Wait Times"