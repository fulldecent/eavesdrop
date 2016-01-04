#line 2 "SMPieChartView.m"		// Causes the __FILE__ preprocessor macro used in NSxxxxAssert to not contain the file path
//
//  SMPieChartView.m
//  Part of the SM2DGraphView framework.
//
//    SM2DGraphView Copyright 2002-2009 Snowmint Creative Solutions LLC.
//    http://www.snowmintcs.com/
//
#import "SMPieChartView.h"
#import "CTGradient.h"

// Set this to one to turn on a timer that NSLogs how long it takes to draw all the slices on a chart.
#define	SMPIE_TIMER					0

typedef struct
{
    // Data that is encoded with the object.
    NSColor     *backgroundColor;
    NSColor     *borderColor;
    id          title;          // Can be NSString * or NSAttributedString *
    int         tag;
    float       explodeDistance;
    SMTitlePosition titlePosition;
    SMLabelPositionEnum labelPosition;

    // From here down is mostly cached data used during an object's lifetime only.
    NSMutableDictionary	*textAttributes;
    NSMutableArray		*sliceAttributes;
    NSMutableArray		*sliceData;         // Flat array of NSNumber objects.
    NSMutableArray      *slicePaths;        // NSBezierPath objects for each slice (already exploded).

    float               totalPieScale;

    NSRect				pieRect;
    NSRect              labelRect;

    struct
    {
        unsigned char	dataSourceIsValid : 1;
        unsigned char	dataSourceDecidesAttributes : 1;
        unsigned char	dataSourceHasExplodedData : 1;
        unsigned char	dataSourceWantsData_asDouble : 1;
        unsigned char	dataSourceWantsData_asObject : 1;
        unsigned char	delegateLabelsSlices : 1;
        unsigned char	delegateWantsMouseDowns : 1;
        unsigned char	delegateWantsEndDraw : 1;
    } flags;

} SMPieChartPrivateData;

// Macro for easily getting to the private data structure of an object.
#define myPrivateData	((__strong SMPieChartPrivateData *)_SMPieChartView_Private)

// Pixels between the label and edges of other things (labels, graph paper, etc).
#define kSM2DGraph_LabelSpacing	4

// Prototypes for internal functions and methods.
static NSDictionary *_sm_local_defaultSliceAttributes( unsigned int inSliceIndex );

@interface SMPieChartView(Private)
- (void)_sm_frameDidChange:(NSNotification *)inNote;
- (void)_sm_calculatePieRect;
- (void)_sm_calculateSlicePaths;
//- (void)_sm_calculateToolTips;
@end

@implementation SMPieChartView

+ (void)initialize
{
    // Set our class version number.  This is used during encoding/decoding.
    [ SMPieChartView setVersion:2 ];

    if ( [ SMPieChartView respondsToSelector:@selector(exposeBinding:) ] )
    {
        [ SMPieChartView exposeBinding:@"backgroundColor" ];
        [ SMPieChartView exposeBinding:@"borderColor" ];
        [ SMPieChartView exposeBinding:@"title" ];
        [ SMPieChartView exposeBinding:@"attributedTitle" ];
        [ SMPieChartView exposeBinding:@"titlePosition" ];
        [ SMPieChartView exposeBinding:@"labelPosition" ];
        [ SMPieChartView exposeBinding:@"explodeDistance" ];
    }
}

- (id)initWithFrame:(NSRect)frame
{
    self = [ super initWithFrame:frame ];
    if ( nil != self )
    {	// Initialization code here.
		if ( nil != NSClassFromString( @"NSGarbageCollector" )
					&& [ NSClassFromString( @"NSGarbageCollector" ) defaultCollector] != nil )
		{	// the Garbage Collector is on
			_SMPieChartView_Private = NSAllocateCollectable( sizeof(SMPieChartPrivateData), NSScannedOption );
			memset( _SMPieChartView_Private, 0, sizeof(SMPieChartPrivateData) );
		}
		else
		{	// retain/release/autorelease/dealloc are being utilized
			_SMPieChartView_Private = calloc( 1, sizeof(SMPieChartPrivateData) );
		}
        NSAssert( nil != _SMPieChartView_Private, NSLocalizedString( @"SMPieChartView failed private memory allocation",
                    @"SMPieChartView failed private memory allocation" ) );

        myPrivateData->backgroundColor = [ [ NSColor whiteColor ] copy ];
        myPrivateData->borderColor = [ [ NSColor blackColor ] retain ];
        myPrivateData->textAttributes = [ [ NSMutableDictionary dictionaryWithObjectsAndKeys:
                    [ NSFont labelFontOfSize:[ NSFont labelFontSize ] ], NSFontAttributeName,
                    nil ] retain ];

        myPrivateData->flags.dataSourceIsValid = NO;
        myPrivateData->flags.dataSourceDecidesAttributes = NO;
        myPrivateData->flags.dataSourceWantsData_asDouble = NO;
        myPrivateData->flags.dataSourceWantsData_asObject = NO;
        myPrivateData->flags.delegateLabelsSlices = NO;
        myPrivateData->flags.delegateWantsMouseDowns = NO;
        myPrivateData->flags.delegateWantsEndDraw = NO;

        [ self _sm_calculatePieRect ];
        [ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(_sm_frameDidChange:)
                    name:NSViewFrameDidChangeNotification object:self ];
    }
    return self;
}

- (void)dealloc
{
    [ [ NSNotificationCenter defaultCenter ] removeObserver:self ];

	[ myPrivateData->backgroundColor release ];
    [ myPrivateData->borderColor release ];
    [ myPrivateData->title release ];
    [ myPrivateData->sliceAttributes release ];
    [ myPrivateData->sliceData release ];
    [ myPrivateData->slicePaths release ];
    [ myPrivateData->textAttributes release ];
    free( _SMPieChartView_Private );

    [ super dealloc ];
}

#pragma mark -

- (id)initWithCoder:(NSCoder *)decoder
{
    unsigned		versionNumber;
    float           tempFloat;
    int             tempInt;

    self = [ super initWithCoder:decoder ];

    // Allocate our private memory.
	if ( nil != NSClassFromString( @"NSGarbageCollector" )
				&& [ NSClassFromString( @"NSGarbageCollector" ) defaultCollector] != nil )
	{	// the Garbage Collector is on
		_SMPieChartView_Private = NSAllocateCollectable( sizeof(SMPieChartPrivateData), NSScannedOption );
		memset( _SMPieChartView_Private, 0, sizeof(SMPieChartPrivateData) );
	}
	else
	{	// retain/release/autorelease/dealloc are being utilized
		_SMPieChartView_Private = calloc( 1, sizeof(SMPieChartPrivateData) );
	}
    NSAssert( nil != _SMPieChartView_Private, NSLocalizedString( @"SMPieChartView failed private memory allocation",
                @"SMPieChartView failed private memory allocation" ) );

    // Start filling in objects.
    myPrivateData->title = [ [ decoder decodeObject ] copy ];

    myPrivateData->backgroundColor = [ [ decoder decodeObject ] copy ];

    myPrivateData->borderColor = [ [ decoder decodeObject ] copy ];

    [ decoder decodeValueOfObjCType:@encode(int) at:&tempInt ];
    myPrivateData->titlePosition = tempInt;

    [ decoder decodeValueOfObjCType:@encode(float) at:&tempFloat ];
    myPrivateData->explodeDistance = tempFloat;

    [ decoder decodeValueOfObjCType:@encode(int) at:&tempInt ];
    myPrivateData->tag = tempInt;

    // Determine version number of encoded class.
    versionNumber = [ decoder versionForClassName:NSStringFromClass( [ SMPieChartView class ] ) ];

    if ( versionNumber >= 2 )
    {
        // Added label positions in version 2 of the class
        [ decoder decodeValueOfObjCType:@encode(int) at:&tempInt ];
        myPrivateData->labelPosition = tempInt;
    }

    myPrivateData->textAttributes = [ [ NSMutableDictionary dictionaryWithObjectsAndKeys:
                [ NSFont labelFontOfSize:[ NSFont labelFontSize ] ], NSFontAttributeName,
                nil ] retain ];

    myPrivateData->flags.dataSourceIsValid = NO;
    myPrivateData->flags.dataSourceDecidesAttributes = NO;
    myPrivateData->flags.dataSourceWantsData_asDouble = NO;
    myPrivateData->flags.dataSourceWantsData_asObject = NO;
    myPrivateData->flags.delegateLabelsSlices = NO;
    myPrivateData->flags.delegateWantsMouseDowns = NO;
    myPrivateData->flags.delegateWantsEndDraw = NO;

    [ self _sm_calculatePieRect ];
    [ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(_sm_frameDidChange:)
                name:NSViewFrameDidChangeNotification object:self ];

    return self;
}

- (void)awakeFromNib
{
    // This is not called in Interface Builder, but it is called when this view has been saved in a nib file
    // and loaded into an application.
    [ self _sm_calculatePieRect ];

    [ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(_sm_frameDidChange:)
                name:NSViewFrameDidChangeNotification object:self ];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    float       tempFloat;
    int         tempInt;

    [ super encodeWithCoder:coder ];

    // NOTE: The class version number is automatically encoded by Cocoa.

	// Archive our data here.
    [ coder encodeObject:myPrivateData->title ];

    [ coder encodeObject:myPrivateData->backgroundColor ];

    [ coder encodeObject:myPrivateData->borderColor ];

    tempInt = myPrivateData->titlePosition;
    [ coder encodeValueOfObjCType:@encode(int) at:&tempInt ];

    tempFloat = myPrivateData->explodeDistance;
    [ coder encodeValueOfObjCType:@encode(float) at:&tempFloat ];

    tempInt = myPrivateData->tag;
    [ coder encodeValueOfObjCType:@encode(int) at:&tempInt ];

    tempInt = myPrivateData->labelPosition;
    [ coder encodeValueOfObjCType:@encode(int) at:&tempInt ];
}

- (Class)valueClassForBinding:(NSString *)binding
{
    Class   result = nil;

    if ( [ binding isEqualToString:@"backgroundColor" ] ||
                [ binding isEqualToString:@"borderColor" ] )
        result = [ NSColor class ];
    else if ( [ binding isEqualToString:@"title" ] )
        result = [ NSString class ];
    else if ( [ binding isEqualToString:@"attributedTitle" ] )
        result = [ NSAttributedString class ];
    else if ( [ binding isEqualToString:@"explodeDistance" ] ||
                [ binding isEqualToString:@"titlePosition" ] ||
                [ binding isEqualToString:@"labelPosition" ] )
        result = [ NSNumber class ];
    else if ( [ [ super class ] instancesRespondToSelector:@selector(valueClassForBinding:) ] )
        result = [ super valueClassForBinding:binding ];

    return result;
}

#pragma mark -

#define kLabelSquareSize    11.0

- (void)drawRect:(NSRect)rect
{
    unsigned int	sliceCount, sliceIndex;
#if defined( SMPIE_TIMER ) && ( SMPIE_TIMER == 1 )
    NSDate			*timer;
    NSTimeInterval	timeInterval;
#endif
    NSBezierPath	*path;
    NSString        *tempString;
    NSAttributedString		*tempAttrString;
    NSColor			*t_color = nil;
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_2
	NSGraphicsContext	*context = [ NSGraphicsContext currentContext ];
	CTGradient			*gradient;
#endif
    NSRect			bounds = [ self bounds ], pieRect, drawRect;

    pieRect = myPrivateData->pieRect;

    if ( nil != [ self title ] && 0 != [ [ self title ] length ] )
    {
        // Draw the title.
        tempAttrString = [ self attributedTitle ];
        drawRect.size = [ tempAttrString size ];
        if ( [ self titlePosition ] == SMTitlePositionBelow )
            drawRect.origin.y = bounds.origin.y;
        else
            drawRect.origin.y = bounds.origin.y + bounds.size.height - drawRect.size.height;

        drawRect.origin.x = pieRect.origin.x + ( pieRect.size.width - drawRect.size.width ) / 2.0;
        if ( NSIntersectsRect( drawRect, rect ) )
        {
            [ tempAttrString drawInRect:drawRect ];
#if defined( SM_DEBUG_DRAWING ) && ( SM_DEBUG_DRAWING == 1 )
            NSFrameRect( drawRect );
#endif
        }
    }

    if ( NSIntersectsRect( pieRect, rect ) )
    {
        if ( nil != myPrivateData->slicePaths && [ myPrivateData->slicePaths count ] > 0 )
//                    && ![ self inLiveResize ] )
        {
#if defined( SMPIE_TIMER ) && ( SMPIE_TIMER == 1 )
            timer = [ NSDate date ];
#endif

            sliceCount = [ myPrivateData->slicePaths count ];
            for ( sliceIndex = 0; sliceIndex < sliceCount; sliceIndex++ )
            {
                BOOL		tempBool = YES;
                path = [ myPrivateData->slicePaths objectAtIndex:sliceIndex ];

                // Go ahead and fill the slice.
                t_color = [ [ myPrivateData->sliceAttributes objectAtIndex:sliceIndex ]
                            objectForKey:NSBackgroundColorAttributeName ];
                if ( nil == t_color )
					t_color = [ self backgroundColor ];

#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_2
				// Now to do some highlights with CTGradient (requires 10.2 as a minimum version)
				[ context saveGraphicsState ];

				// Create a gradient that goes from 30% darker than to 30% lighter than requested color.
				gradient = [ CTGradient
							gradientWithBeginningColor:[ t_color blendedColorWithFraction:0.3 ofColor:[ NSColor blackColor ] ]
							endingColor:[ t_color blendedColorWithFraction:0.3 ofColor:[ NSColor whiteColor ] ]
							];

				[ gradient fillBezierPath:path angle:90.0 ];	// light on top, dark on bottom.
				[ context restoreGraphicsState ];
#else
				// Basic color fill.
				[ t_color set ];
                [ path fill ];
#endif // highlights with CTGradient

                [ path setLineWidth:1.0 ];
				[ path setMiterLimit:2.0 ];

                // Go ahead and draw the border of the slice.
                t_color = [ [ myPrivateData->sliceAttributes objectAtIndex:sliceIndex ]
                            objectForKey:NSForegroundColorAttributeName ];
                if ( nil != t_color )
                    [ t_color set ];
                else
                    [ [ self borderColor ] set ];

                if ( tempBool )
                {
                    [ path stroke ];
                } // if line width is not "none".
            } // end of this slice.

#if defined( SMPIE_TIMER ) && ( SMPIE_TIMER == 1 )
            timeInterval = [ timer timeIntervalSinceNow ];
            NSLog( @"drawing all slices took this long: %g", timeInterval );
#endif
        } // end have to draw our slices.
        else
        {
            NSBezierPath    *explodedCircle, *pieCircle;

            // We have no slices.  Just draw a circle.
            pieCircle = [ NSBezierPath bezierPathWithOvalInRect:pieRect ];

            if ( [ self explodeDistance ] >= 0.5 )
            {
                pieRect = NSInsetRect( pieRect, -[ self explodeDistance ], -[ self explodeDistance ] );
                explodedCircle = [ NSBezierPath bezierPathWithOvalInRect:pieRect ];
                // pieRect = myPrivateData->pieRect;
            }
            else
                explodedCircle = pieCircle;

            // Draw the background of the pie.
            [ myPrivateData->backgroundColor set ];
            [ explodedCircle fill ];

            // Frame it in the border color.
            [ [ self borderColor ] set ];
            [ explodedCircle stroke ];
            [ pieCircle stroke ];
        }
    }

    if ( myPrivateData->labelPosition != SMLabelPositionNone )
    {
        if ( nil != myPrivateData->slicePaths && [ myPrivateData->slicePaths count ] > 0 )
//                    && ![ self inLiveResize ] )
        {
            sliceCount = [ myPrivateData->slicePaths count ];
            for ( sliceIndex = 0; sliceIndex < sliceCount; sliceIndex++ )
            {
                if ( myPrivateData->flags.delegateLabelsSlices )
                    tempString = [ [ self delegate ] pieChartView:self labelForSliceIndex:sliceIndex ];
                else
                    tempString = nil;

                if ( nil == tempString )
                    tempString = [ NSString stringWithFormat:@"%d", sliceIndex ];

                t_color = [ [ myPrivateData->sliceAttributes objectAtIndex:sliceIndex ]
                            objectForKey:NSBackgroundColorAttributeName ];
                if ( nil == t_color )
                    t_color = [ self backgroundColor ];

                if ( nil != tempString )
                {
                    // Calculate drawing rectangle
                    drawRect.origin.y = myPrivateData->labelRect.origin.y +
                                myPrivateData->labelRect.size.height -
                                ( ( sliceIndex + 1 ) * ( kLabelSquareSize + 2.0 ) );
                    drawRect.origin.x = myPrivateData->labelRect.origin.x;

                    drawRect.size.width = drawRect.size.height = kLabelSquareSize;
                    if ( NSIntersectsRect( drawRect, rect ) )
                    {
                        [ t_color set ];
                        NSRectFillUsingOperation( NSInsetRect( drawRect, 1.0, 1.0 ), NSCompositeSourceOver );
                        [ [ NSColor blackColor ] set ];
                        NSFrameRect( drawRect );
                    }

                    drawRect.origin.x += kLabelSquareSize + 3.0;
                    drawRect.size = [ tempString sizeWithAttributes:myPrivateData->textAttributes ];
                    if ( NSIntersectsRect( drawRect, rect ) )
                    {
                        [ tempString drawInRect:drawRect withAttributes:myPrivateData->textAttributes ];
                    }
                }
            }
        }
    }

    // Signal the delegate that we're done.
    if ( myPrivateData->flags.delegateWantsEndDraw )
        [ [ self delegate ] pieChartViewCompletedDrawing:self ];
}

/*- (void)viewDidEndLiveResize
{
    // Make sure we redisplay so the data slices show up in the graph.
    [ super viewDidEndLiveResize ];
    [ self setNeedsDisplay:YES ];
}*/

- (void)mouseDown:(NSEvent *)inEvent
{
    if ( myPrivateData->flags.delegateWantsMouseDowns )
    {
        NSPoint		curPoint;

        curPoint = [ self convertPoint:[ inEvent locationInWindow ] fromView:nil ];

        // Do we want to track until mouse up and THEN call the delegate?
        [ [ self delegate ] pieChartView:self didClickPoint:curPoint ];
    }
    else
        [ super mouseDown:inEvent ];
}

- (void)print:(id)sender
{
	NSPrintInfo		*print_info;

	// Set the pagination so that we will be scaled down to fit on a page if necessary.
	print_info = [ NSPrintInfo sharedPrintInfo ];
	[ print_info setHorizontalPagination:NSFitPagination ];
	[ print_info setVerticalPagination:NSFitPagination ];

	[ [ NSPrintOperation printOperationWithView:self printInfo:print_info ] runOperation ];
}

/*- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData
{
	NSString	*result = nil;
	int			sliceIndex;

	if ( myPrivateData->flags.delegateLabelsSlices )
	{
		sliceIndex = [ self convertToSliceFromPoint:point fromView:self ];
		if ( -1 != sliceIndex )
			result = [ [ self delegate ] pieChartView:self labelForSliceIndex:sliceIndex ];
	}

	return result;
}*/

#pragma mark -
#pragma mark • ACCESSORS

- (void)setDataSource:(id)inDataSource
{
    BOOL	failed = NO;

	dataSource = inDataSource;

    // Assert some checks on the data source.
    if ( ![ dataSource respondsToSelector:@selector(numberOfSlicesInPieChartView:) ] )
    {
        failed = YES;
        NSLog( @"SMPieChartView data source does not respond to selector -numberOfSlicesInPieChartView:" );
    }
    if ( ![ dataSource respondsToSelector:@selector(pieChartView:dataForSliceIndex:) ] &&
                ![ dataSource respondsToSelector:@selector(pieChartViewArrayOfSliceData:) ] )
    {
        failed = YES;
        NSLog( @"SMPieChartView data source does not respond to selector -pieChartView:dataForSliceIndex: or -pieChartViewArrayOfSliceData:" );
    }

    myPrivateData->flags.dataSourceIsValid = !failed;

    // Check for optional methods.
    myPrivateData->flags.dataSourceHasExplodedData = ( [ dataSource
                respondsToSelector:@selector(numberOfExplodedPartsInPieChartView:) ] &&
                [ dataSource respondsToSelector:@selector(pieChartView:rangeOfExplodedPartIndex:) ] );

    myPrivateData->flags.dataSourceDecidesAttributes = [ dataSource
                respondsToSelector:@selector(pieChartView:attributesForSliceIndex:) ];

    myPrivateData->flags.dataSourceWantsData_asDouble = [ dataSource
                respondsToSelector:@selector(pieChartView:dataForSliceIndex:) ];
    myPrivateData->flags.dataSourceWantsData_asObject = [ dataSource
                respondsToSelector:@selector(pieChartViewArrayOfSliceData:) ];
}

- (id)dataSource
{	return dataSource;	}

- (void)setDelegate:(id)inDelegate
{
    delegate = inDelegate;

    myPrivateData->flags.delegateLabelsSlices = [ delegate
                respondsToSelector:@selector(pieChartView:labelForSliceIndex:) ];

    myPrivateData->flags.delegateWantsMouseDowns = [ delegate
                respondsToSelector:@selector(pieChartView:didClickPoint:) ];

    myPrivateData->flags.delegateWantsEndDraw = [ delegate
                respondsToSelector:@selector(pieChartViewCompletedDrawing:) ];
}

- (id)delegate
{	return delegate;	}

- (void)setTag:(int)inTag
{	myPrivateData->tag = inTag;	}

- (int)tag
{	return myPrivateData->tag;	}

- (void)setBackgroundColor:(NSColor *)inColor
{
	[ myPrivateData->backgroundColor release ];
    myPrivateData->backgroundColor = [ inColor copy ];
    [ self setNeedsDisplay:YES ];
}

- (NSColor *)backgroundColor
{	return [ [ myPrivateData->backgroundColor retain ] autorelease ];	}

- (void)setBorderColor:(NSColor *)inColor
{
	[ myPrivateData->borderColor release ];
    myPrivateData->borderColor = [ inColor copy ];
    [ self setNeedsDisplay:YES ];
}

- (NSColor *)borderColor
{	return [ [ myPrivateData->borderColor retain ] autorelease ];	}

- (void)setTitle:(NSString *)inNewTitle
{
    if ( myPrivateData->title != inNewTitle )
    {
        [ myPrivateData->title release ];
        myPrivateData->title = [ inNewTitle copy ];
        [ self _sm_calculatePieRect ];
        [ self setNeedsDisplay:YES ];
    }
}

- (NSString *)title
{
    if ( [ myPrivateData->title isKindOfClass:[ NSAttributedString class ] ] )
        return [ myPrivateData->title string ];
    else
        return [ [ myPrivateData->title retain ] autorelease ];
}

- (void)setAttributedTitle:(NSAttributedString *)inNewValue
{
    if ( myPrivateData->title != inNewValue )
    {
        [ myPrivateData->title release ];
        myPrivateData->title = [ inNewValue copy ];
        [ self _sm_calculatePieRect ];
        [ self _sm_calculateSlicePaths ];
        [ self setNeedsDisplay:YES ];
    }
}

- (NSAttributedString *)attributedTitle
{
    if ( [ myPrivateData->title isKindOfClass:[ NSString class ] ] )
        return [ [ [ NSAttributedString alloc ] initWithString:myPrivateData->title
                    attributes:myPrivateData->textAttributes ] autorelease ];
    else
        return [ [ myPrivateData->title retain ] autorelease ];
}

- (void)setTitlePosition:(SMTitlePosition)inPosition
{
    if ( myPrivateData->titlePosition != inPosition )
    {
        myPrivateData->titlePosition = inPosition;
        [ self _sm_calculatePieRect ];
        [ self _sm_calculateSlicePaths ];
        [ self setNeedsDisplay:YES ];
    }
}

- (SMTitlePosition)titlePosition
{
	return myPrivateData->titlePosition;
}

- (void)setLabelPosition:(SMLabelPositionEnum)inNewValue
{
    if ( myPrivateData->labelPosition != inNewValue )
    {
        myPrivateData->labelPosition = inNewValue;
        [ self _sm_calculatePieRect ];
        [ self _sm_calculateSlicePaths ];
        [ self setNeedsDisplay:YES ];
    }
}

- (SMLabelPositionEnum)labelPosition
{
	return myPrivateData->labelPosition;
}

- (void)setExplodeDistance:(float)inDistance
{
    if ( myPrivateData->explodeDistance != inDistance )
    {
        myPrivateData->explodeDistance = inDistance;
        [ self _sm_calculatePieRect ];
        [ self _sm_calculateSlicePaths ];
        [ self setNeedsDisplay:YES ];
    }
}

- (float)explodeDistance
{
	return myPrivateData->explodeDistance;
}

#pragma mark -
#pragma mark • OTHER METHODS

- (IBAction)refreshDisplay:(id)sender
{
    [ self reloadData ];
    [ self reloadAttributes ];
}

- (void)reloadData
{
    unsigned int	numSlices, i;
    NSArray         *sliceData = nil;
    double          sliceSize;
    double          total = 0.0;

    if ( myPrivateData->flags.dataSourceIsValid )
    {
        numSlices = [ [ self dataSource ] numberOfSlicesInPieChartView:self ];

        [ myPrivateData->sliceData release ];
        myPrivateData->sliceData = nil;

        if ( myPrivateData->flags.dataSourceWantsData_asObject )
        {
            // Try grabbing an NSArray of NSNumbers.
            sliceData = [ [ self dataSource ] pieChartViewArrayOfSliceData:self ];
            if ( [ sliceData count ] == numSlices )
            {
                // Make a copy of the data for my use.
                myPrivateData->sliceData = [ sliceData copy ];

                // Total up the amount in the pie.
                for ( i = 0; i < numSlices; i++ )
                    total += [ [ myPrivateData->sliceData objectAtIndex:i ] doubleValue ];
            }
            else if ( nil != sliceData )
                NSLog( @"SMPieChartView: The slice data array does not contain the correct number of slices" );
        }

        if ( nil == myPrivateData->sliceData && myPrivateData->flags.dataSourceWantsData_asDouble )
        {
            myPrivateData->sliceData = [ [ NSMutableArray arrayWithCapacity:numSlices ] retain ];

            // Get each slice individually.
            for ( i = 0; i < numSlices; i++ )
            {
                // Grab each slice as a double.
                sliceSize = [ [ self dataSource ] pieChartView:self dataForSliceIndex:i ];

                // Total up the amount in the pie.
                total += sliceSize;

                // Add the slice data to the array.
                [ myPrivateData->sliceData addObject:[ NSNumber numberWithDouble:sliceSize ] ];
            }
        }

        [ self _sm_calculatePieRect ];
    }

    myPrivateData->totalPieScale = total;
    [ self _sm_calculateSlicePaths ];
    [ self setNeedsDisplay:YES ];
}

- (void)reloadAttributes
{
    unsigned int	numSlices, i;
    NSDictionary	*sliceData;

    numSlices = [ [ self dataSource ] numberOfSlicesInPieChartView:self ];
    [ myPrivateData->sliceAttributes release ];
    myPrivateData->sliceAttributes = [ [ NSMutableArray arrayWithCapacity:numSlices ] retain ];

    if ( myPrivateData->flags.dataSourceDecidesAttributes )
    {
        for ( i = 0; i < numSlices; i++ )
        {
            sliceData = [ [ self dataSource ] pieChartView:self attributesForSliceIndex:i ];
            if ( nil == sliceData )
                sliceData = _sm_local_defaultSliceAttributes( i );
            [ myPrivateData->sliceAttributes addObject:sliceData ];
        }
    }
    else
    {
        for ( i = 0; i < numSlices; i++ )
        {
            sliceData = _sm_local_defaultSliceAttributes( i );
            [ myPrivateData->sliceAttributes addObject:sliceData ];
        }
    }

    [ self _sm_calculatePieRect ];
    [ self setNeedsDisplay:YES ];
}

- (void)reloadAttributesForSliceIndex:(unsigned int)inSliceIndex
{
    NSDictionary	*sliceData, *replacingData;

    // Determine if the attribute being replaced was a bar or not (so we can keep the bar count correct).
    replacingData = [ myPrivateData->sliceAttributes objectAtIndex:inSliceIndex ];

    if ( myPrivateData->flags.dataSourceDecidesAttributes )
    {
        // Let the dataSource object figure it out.
        sliceData = [ [ self dataSource ] pieChartView:self attributesForSliceIndex:inSliceIndex ];
        if ( nil == sliceData )
            sliceData = _sm_local_defaultSliceAttributes( inSliceIndex );
    }
    else
        sliceData = _sm_local_defaultSliceAttributes( inSliceIndex );

    [ myPrivateData->sliceAttributes replaceObjectAtIndex:inSliceIndex withObject:sliceData ];

    [ self _sm_calculatePieRect ];
    [ self setNeedsDisplay:YES ];
}

- (NSImage *)imageOfView
{
    NSImage		*result = nil;

    result = [ [ [ NSImage alloc ] initWithSize:[ self bounds ].size ] autorelease ];

    // This provides a cached representation.
    [ result lockFocus ];

    // Fill with a white background.
    [ [ NSColor whiteColor ] set ];
    NSRectFill( [ self bounds ] );

    // Draw the graph.
    [ self drawRect:[ self bounds ] ];

    [ result unlockFocus ];

    return result;
}

- (int)convertToSliceFromPoint:(NSPoint)inPoint fromView:(NSView *)inView
{
    int             result = -1;
    int             sliceIndex, sliceCount;
    NSBezierPath    *path;

    // First, get the point into the coordinate system of this view.
    if ( inView != self )
        inPoint = [ self convertPoint:inPoint fromView:inView ];

    if ( nil != myPrivateData->slicePaths && [ myPrivateData->slicePaths count ] > 0 )
    {
        // Now, determine which slice it was in.
        sliceCount = [ myPrivateData->slicePaths count ];
        for ( sliceIndex = 0; sliceIndex < sliceCount; sliceIndex++ )
        {
            path = [ myPrivateData->slicePaths objectAtIndex:sliceIndex ];
            if ( [ path containsPoint:inPoint ] )
            {
                result = sliceIndex;
                break;
            }
        }
    }

    return result;
}

#pragma mark -
#pragma mark • PRIVATE METHODS

- (void)_sm_frameDidChange:(NSNotification *)inNote
{
    [ self _sm_calculatePieRect ];
    [ self _sm_calculateSlicePaths ];
}

- (void)_sm_calculatePieRect
{
    NSRect		bounds = [ self bounds ], pieRect, labelRect;
    NSRect		tempRect, frame;

    labelRect = pieRect = bounds;
    // Calculate how much room we need.
    labelRect.size.height = [ myPrivateData->slicePaths count ] * ( kLabelSquareSize + 2.0 );

    if ( myPrivateData->labelPosition == SMLabelPositionAbove )
    {
        pieRect.size.height = pieRect.size.width;
        if ( bounds.size.height < pieRect.size.height + labelRect.size.height )
        {
            frame = [ self frame ];
            frame.origin.y -= ( pieRect.size.height + labelRect.size.height ) - bounds.size.height;
            frame.size.height = pieRect.size.height + labelRect.size.height;
            [ self setFrame:frame ];
            bounds = [ self bounds ];
        }
        labelRect.origin.y = pieRect.size.height + 1.0;
    }
    else if ( myPrivateData->labelPosition == SMLabelPositionBelow )
    {
        pieRect.size.height = pieRect.size.width;
        if ( bounds.size.height < pieRect.size.height + labelRect.size.height )
        {
            frame = [ self frame ];
            frame.origin.y -= ( pieRect.size.height + labelRect.size.height ) - bounds.size.height;
            frame.size.height = pieRect.size.height + labelRect.size.height;
            [ self setFrame:frame ];
            bounds = [ self bounds ];
        }
        pieRect.origin.y = bounds.size.height - pieRect.size.height - 1.0;
    }
/*    else if ( myPrivateData->labelPosition == SMLabelPositionRight )
    {
        pieRect.size.width = pieRect.size.height;
    }
    else if ( myPrivateData->labelPosition == SMLabelPositionLeft )
    {
        pieRect.size.width = pieRect.size.height;
        pieRect.origin.x = bounds.size.width - pieRect.size.width - 1.0;
    }*/

    pieRect = NSInsetRect( pieRect, 1, 1 );   // Leave room for the border.
    // Leave room for exploded slices.
    if ( [ self explodeDistance ] >= 0.5 )
        pieRect = NSInsetRect( pieRect, [ self explodeDistance ], [ self explodeDistance ] );

    if ( nil != [ self title ] && 0 != [ [ self title ] length ] )
    {
        // Leave room for the title.
        tempRect.size = [ [ self attributedTitle ] size ];

        if ( [ self titlePosition ] == SMTitlePositionBelow )
        {
            // Leave room below the pie.
            pieRect.origin.y += tempRect.size.height + kSM2DGraph_LabelSpacing;
            pieRect.size.height -= tempRect.size.height + kSM2DGraph_LabelSpacing;
        }
        else
        {
            // Leave room above the pie.
            pieRect.size.height -= tempRect.size.height + kSM2DGraph_LabelSpacing;
			labelRect.origin.y -= tempRect.size.height + kSM2DGraph_LabelSpacing;
		}
    }

    myPrivateData->pieRect = pieRect;
    myPrivateData->labelRect = labelRect;
}

- (void)_sm_calculateSlicePaths
{
    unsigned int	sliceCount, sliceIndex;
    id				dataObj;
    NSBezierPath	*path;
    NSPoint			centerPoint;
    NSRect			pieRect;
    double			radius, sliceDegrees, currentDegrees = 0.0;

    pieRect = myPrivateData->pieRect;

    [ myPrivateData->slicePaths release ];
    myPrivateData->slicePaths = nil;

    if ( nil == myPrivateData->sliceData || [ myPrivateData->sliceData count ] == 0 )
	{
//		[ self _sm_calculateToolTips ];
        return;
	}

    // Calculate radius.
    radius = pieRect.size.width / 2.0;
    if ( radius > pieRect.size.height / 2.0 )
        radius = pieRect.size.height / 2.0;

    // Calculate center point.
    centerPoint.x = NSMidX( pieRect );
    centerPoint.y = NSMidY( pieRect );

    sliceCount = [ myPrivateData->sliceData count ];
    myPrivateData->slicePaths = [ [ NSMutableArray arrayWithCapacity:sliceCount ] retain ];

    for ( sliceIndex = 0; sliceIndex < sliceCount; sliceIndex++ )
    {
        dataObj = [ myPrivateData->sliceData objectAtIndex:sliceIndex ];

        // Scale the dataPoint into the whole pie correctly.
        if ( 0.0 != myPrivateData->totalPieScale )
            sliceDegrees = [ dataObj doubleValue ] * 360.0 / myPrivateData->totalPieScale;
        else
            sliceDegrees = 360.0 / sliceCount;

        path = [ NSBezierPath bezierPath ];
        [ path appendBezierPathWithArcWithCenter:centerPoint radius:radius
                    startAngle:currentDegrees endAngle:sliceDegrees + currentDegrees ];
        [ path lineToPoint:centerPoint ];
        [ path closePath ];

        [ myPrivateData->slicePaths addObject:path ];

        currentDegrees += sliceDegrees;
    }

    if ( myPrivateData->flags.dataSourceHasExplodedData )
    {
        // Now, I need to determine which slices are exploded
        id					transform;
        int                 explodeCount, explodeIndex;
        NSRange             explodeRange;
        float               startExplode, endExplode;

        explodeCount = [ [ self dataSource ] numberOfExplodedPartsInPieChartView:self ];
        for ( explodeIndex = 0; explodeIndex < explodeCount; explodeIndex++ )
        {
            explodeRange = [ [ self dataSource ] pieChartView:self rangeOfExplodedPartIndex:explodeIndex ];
            startExplode = 0.0;
            endExplode = 360.0;

            // Calculate the start and end point degrees for this explode group.
            currentDegrees = 0.0;
            for ( sliceIndex = 0; sliceIndex < sliceCount; sliceIndex++ )
            {
                dataObj = [ myPrivateData->sliceData objectAtIndex:sliceIndex ];

                if ( 0.0 != myPrivateData->totalPieScale )
                    sliceDegrees = [ dataObj doubleValue ] * 360.0 / myPrivateData->totalPieScale;
                else
                    sliceDegrees = 360.0 / sliceCount;

                if ( sliceIndex == explodeRange.location )
                    startExplode = currentDegrees;

                if ( sliceIndex == explodeRange.location + explodeRange.length )
                {
                    endExplode = currentDegrees;
                    break;
                }

                currentDegrees += sliceDegrees;
            }

            // Calculate the transform to explode this group of slices.
            transform = [ NSClassFromString( @"NSAffineTransform" ) transform ];
            [ transform rotateByDegrees:( startExplode + endExplode ) / 2.0 ];
            [ transform translateXBy:[ self explodeDistance ] yBy:0.0 ];
            [ transform rotateByDegrees:-( startExplode + endExplode ) / 2.0 ];

            for ( sliceIndex = explodeRange.location; sliceIndex < sliceCount &&
                        sliceIndex < explodeRange.location + explodeRange.length; sliceIndex++ )
            {
                // Transform each of the slice paths in this explode group.
                path = [ myPrivateData->slicePaths objectAtIndex:sliceIndex ];
                [ path transformUsingAffineTransform:transform ];
            }
        }
    }

//	[ self _sm_calculateToolTips ];
}

/*- (void)_sm_calculateToolTips
{
	if ( myPrivateData->flags.delegateLabelsSlices &&
				0 != ( myPrivateData->labelPosition & SMLabelPositionToolTip ) &&
				nil != myPrivateData->slicePaths && [ myPrivateData->slicePaths count ] > 0 )
	{
		// Each slice needs it's own tool tip.
		// However, Cocoa uses rectangles for tooltip tracking.  Yikes.
		int             sliceIndex, sliceCount;
		NSBezierPath    *path;
		NSRect			tipRect;

		[ self removeAllToolTips ];

		// Now, determine where each slice is.
		sliceCount = [ myPrivateData->slicePaths count ];
		for ( sliceIndex = 0; sliceIndex < sliceCount; sliceIndex++ )
		{
			path = [ myPrivateData->slicePaths objectAtIndex:sliceIndex ];
			tipRect = [ path bounds ];
			tipRect = NSInsetRect( tipRect, 3, 3 );
			NSLog( @"Adding tooltip in rect:%@", NSStringFromRect( tipRect ) );
			myPrivateData->toolTipTag = [ self addToolTipRect:tipRect owner:self userData:nil ];
        }
	}
	else
	{
		// Remove all tool tip labels that were added.
//		[ self removeToolTip:myPrivateData->toolTipTag ];
//		NSLog( @"Removing all tooltips." );
		[ self removeAllToolTips ];
	}
}*/

#pragma mark -
#pragma mark • LOCAL FUNCTIONS

static NSDictionary *_sm_local_defaultSliceAttributes( unsigned int inSliceIndex )
{
    NSColor		*t_color;

    switch ( inSliceIndex % 7 )
    {
    default:
    case 0:		t_color = [ NSColor blackColor ];		break;
    case 1:		t_color = [ NSColor redColor ];		break;
    case 2:		t_color = [ NSColor greenColor ];		break;
    case 3:		t_color = [ NSColor blueColor ];		break;
    case 4:		t_color = [ NSColor yellowColor ];	break;
    case 5:		t_color = [ NSColor cyanColor ];		break;
    case 6:		t_color = [ NSColor magentaColor ];	break;
    }

    return [ NSDictionary dictionaryWithObject:t_color forKey:NSBackgroundColorAttributeName ];
}

@end
