//
//  TextDecoder.m
//  Eavesdrop
//
//  Created by Eric Baur on 11/11/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import "TextDecoder.h"


@implementation TextDecoder

+ (void)initialize
{
	ENTRY( @"initialize" );
	[self setKeys:[NSArray arrayWithObject:@"representation"]
		triggerChangeNotificationsForDependentKey:@"payloadAsAttributedString"];
}

+ (BOOL)canDecodePayload:(NSData *)payload
{
	if ( [payload length] > 0 )
		return YES;
	else
		return NO;
}

- (id)initWithPayload:(NSData *)startingPayload
{
	self = [super initWithPayload:startingPayload];
	if (self) {
		//do something interesting here...
	}
	return self;
}

- (void)awakeFromNib
{
	ENTRY1( @"awakeFromNib - text view: %@", [textDecoderView description] );
}

- (NSString *)decoderNibName
{
	return @"TextDecoder";
}

- (NSView *)textDecoderView
{
	ENTRY( @"textDecoderView" );
	return textDecoderView;
}

- (NSAttributedString *)payloadAsAttributedString
{
	ENTRY( @"payloadAsAttributedString" );
	NSMutableAttributedString *tempString = [[[NSMutableAttributedString alloc] init] autorelease];

	NSColor *textColor = [NSColor grayColor];
	unsigned char *buffer;
	unsigned char *output;
	unsigned int bufferLen, outputLen;
	unsigned int i, j, k;
	unsigned char space = ' ';
	unsigned char newline = '\n';
	unsigned char vertbar = '|';
	unsigned char *hexDigits = (unsigned char *)"0123456789ABCDEF";


	bufferLen = [payloadData length];
	buffer = malloc( bufferLen );	//need to make sure this was successful...

	[payloadData getBytes:buffer];

	if (representation>2 || representation<0) {	//this line needs to change if more types are added
		NSLog( @"No valid representation specified: using CONVERSATION_ASCII" );
		representation = CONVERSATION_ASCII;
	}
	
/* CONVERSATION_ASCII calculations */
	if (representation==CONVERSATION_ASCII) {
		DEBUG( @"processing CONVERSATION_ASCII" );
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
		DEBUG( @"processing CONVERSATION_HEX" );
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
		DEBUG( @"processing CONVERSATION_HEX_ASCII" );
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
	
	//DEBUG2( @"\no:\t%d\nj:\t%d\n", outputLen, j );
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

	return [tempString copy];
}

@end
