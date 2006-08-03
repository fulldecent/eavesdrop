
#import "CaptureDocument.h"

@implementation CaptureDocument (Delegates)

- (BOOL)isValidFilter:(NSString *)filterString
{
	char errbuf[PCAP_ERRBUF_SIZE];  /* Error buffer */    
	bpf_u_int32 maskp;              /* subnet mask */
	bpf_u_int32 netp;               /* ip */
	struct bpf_program fp;
	
	char filter_app[ [filterString cStringLength] ];
	[filterString getCString:filter_app];

	pcap_lookupnet("en0", &netp, &maskp, errbuf);
	// I have no idea what the first two integers are for...
	if( pcap_compile_nopcap(1,1,&fp,filter_app,0,netp)==-1) {
		return NO;
	} else {
		return YES;
	}
}

- (void)setColorForFilter
{
	if ( [self isValidFilter:[filterTextField stringValue]] ) {
		[filterTextField setBackgroundColor:[NSColor colorWithCalibratedRed:0.75 green:1 blue:0.75 alpha:1]];	
	} else {
		[filterTextField setBackgroundColor:[NSColor colorWithCalibratedRed:1 green:0.75 blue:0.75 alpha:1]];
	}
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{	
	if ( checkTimer ) {
		[checkTimer invalidate];
		[checkTimer release];
	}	
	
	checkTimer = [NSTimer
		scheduledTimerWithTimeInterval:1.0
		target:self
		selector:@selector(setColorForFilter)
		userInfo:nil
		repeats:NO
	];
	[checkTimer retain];
}

@end