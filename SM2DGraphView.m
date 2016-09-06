#line 2 "SM2DGraphView.m"		// Causes the __FILE__ preprocessor macro used in NSxxxxAssert to not contain the file path
//
//  SM2DGraphView.m
//  Part of the SM2DGraphView framework.
//
//    SM2DGraphView Copyright 2002-2009 Snowmint Creative Solutions LLC.
//    http://www.snowmintcs.com/
//
#import <Accelerate/Accelerate.h>
#import "SM2DGraphView.h"
#import "CTGradient.h"

#import <inttypes.h>

// Set this to zero if you want to use NSBezierPath.  I don't know why you would, since NSBezierPath is slightly slower.
#define SM2D_USE_CORE_GRAPHICS		0
// Set this to one to turn on a timer that NSLogs how long it takes to draw all the lines on a graph.
// Set to zero for no timer.  Set to 1 for timing all drawing.  Set to 2 for scaling timing.
#define	SM2D_TIMER					0

/*!	@enum	SM2DGraphScaleTypeEnum
    @discussion	Scale types to be used on each graph axis.  This is unimplemented currently.
    @constant	kSM2DGraphScaleType_Linear	Normal linear scale.
    @constant	kSM2DGraphScaleType_Log10	Log base 10 scale.
    @constant	kSM2DGraphScaleType_Default	Default scale for both axis - equal to linear.
*/
typedef NS_ENUM(unsigned int, SM2DGraphScaleTypeEnum)
{
    kSM2DGraphScaleType_Linear,
    kSM2DGraphScaleType_Log10,

    kSM2DGraphScaleType_Default = kSM2DGraphScaleType_Linear
};

// Some unimplemented methods.
//- (void)setScaleType:(SM2DGraphScaleTypeEnum)inNewValue forAxis:(SM2DGraphAxisEnum)inAxis;
//- (SM2DGraphScaleTypeEnum)scaleTypeForAxis:(SM2DGraphAxisEnum)inAxis;

// The attribute keys.
NSString *SM2DGraphLineSymbolAttributeName = @"SM2DGraphLineSymbolAttributeName";
NSString *SM2DGraphBarStyleAttributeName = @"SM2DGraphBarStyleAttributeName";
NSString *SM2DGraphLineWidthAttributeName = @"SM2DGraphLineWidthAttributeName";
NSString *SM2DGraphDontAntialiasAttributeName = @"SM2DGraphDontAntialiasAttributeName";
NSString *SM2DGraphLineDashAttributeName = @"SM2DGraphLineDashAttributeName";

// Data stored for each axis.
typedef struct
{
	NSString				*label;
	SM2DGraphScaleTypeEnum	scaleType;
	NSInteger				numberOfTickMarks, numberOfMinorTickMarks;
	CGFloat					inset;
	BOOL					drawLineAtZero;
	NSTickMarkPosition		tickMarkPosition;
} SM2DGraphAxisRecord;

typedef unsigned char bitFieldType;
typedef struct
{
    // Data that is encoded with the object.
	NSColor	*backgroundColor;
	NSColor	*gridColor;
	NSColor	*borderColor;
	id		title;

	NSInteger   tag;

	SM2DGraphAxisRecord	yAxisInfo;
	SM2DGraphAxisRecord	yRightAxisInfo;
	SM2DGraphAxisRecord	xAxisInfo;

    // From here down is mostly cached data used during an object's lifetime only.
	NSMutableDictionary	*textAttributes;
	NSMutableArray		*lineAttributes;
	NSMutableArray		*lineData;
	int					barCount;

	NSRect				graphPaperRect;
	NSRect				graphRect;

	struct
	{
		bitFieldType    useVectorComputation : 1;
		bitFieldType	liveRefresh : 1;
		bitFieldType	drawsGrid : 1;		// This flag is stored in the coding/decoding process.
		bitFieldType	dataSourceIsValid : 1;
		bitFieldType	dataSourceDecidesAttributes : 1;
		bitFieldType	dataSourceWantsDataArray : 1;
		bitFieldType	dataSourceWantsDataChunk : 1;
		bitFieldType	delegateLabelsTickMarks : 1;
		bitFieldType    delegateChangesBarAttrs : 1;
		bitFieldType	delegateWantsMouseDowns : 1;
		bitFieldType	delegateWantsEndDraw : 1;
	} flags;

} SM2DPrivateData;

// Macro for easily getting to the private data structure of an object.
#define myPrivateData	((__strong SM2DPrivateData *)_SM2DGraphView_Private)

// Pixels between the label and edges of other things (labels, graph paper, etc).
#define kSM2DGraph_LabelSpacing	4

// Prototypes for internal functions and methods.
static SM2DGraphAxisRecord *_sm_local_determineAxis( SM2DGraphAxisEnum inAxis, SM2DPrivateData *inPrivateData );
static NSString *_sm_local_getSymbolForEnum( SM2DGraphSymbolTypeEnum inValue );
static NSDictionary *_sm_local_defaultLineAttributes( NSUInteger inLineIndex );
static NSDictionary *_sm_local_encodeAxisInfo( SM2DGraphAxisRecord *inAxis );
static void _sm_local_decodeAxisInfo( NSDictionary *inInfo, SM2DGraphAxisRecord *outAxis );
static NSBezierPath *_sm_local_bar_bezier_path( NSRect inRect, unsigned char inRoundedEdge, CGFloat inRadius );

#if __ppc__
	static BOOL _sm_local_isAltiVecPresent( void );
	static void _sm_local_scaleDataUsingVelocityEngine( NSPoint *ioPoints, unsigned long inDataCount,
                                CGFloat minX, CGFloat xScale, CGFloat xOrigin,
                                CGFloat minY, CGFloat yScale, CGFloat yOrigin );
#endif

@interface SM2DGraphView(Private)
- (void)_sm_drawGridInRect:(NSRect)inRect;
#if SM2D_USE_CORE_GRAPHICS
- (void)_sm_drawSymbol:(SM2DGraphSymbolTypeEnum)inSymbol onLine:(NSPoint *)inLine count:(NSInteger)inPointCount
            inColor:(NSColor *)inColor inRect:(NSRect)inRect;
#else
- (void)_sm_drawSymbol:(SM2DGraphSymbolTypeEnum)inSymbol onLine:(NSBezierPath *)inLine inColor:(NSColor *)inColor
            inRect:(NSRect)inRect;
#endif
- (void)_sm_drawVertBarFromPoint:(NSPoint)inFromPoint toPoint:(NSPoint)inToPoint barNumber:(NSInteger)inBarNumber
            of:(NSInteger)inBarCount inColor:(NSColor *)inColor;
- (void)_sm_frameDidChange:(NSNotification *)inNote;
- (void)_sm_calculateGraphPaperRect;
@end

@implementation SM2DGraphView

+ (void)initialize
{
    // Set our class version number.  This is used during encoding/decoding.
    [ SM2DGraphView setVersion:4 ];

    // Possibly expose some bindings.
    if ( [ SM2DGraphView respondsToSelector:@selector(exposeBinding:) ] )
    {
        [ SM2DGraphView exposeBinding:@"backgroundColor" ];
        [ SM2DGraphView exposeBinding:@"borderColor" ];
        [ SM2DGraphView exposeBinding:@"gridColor" ];
        [ SM2DGraphView exposeBinding:@"drawsGrid" ];
        [ SM2DGraphView exposeBinding:@"title" ];
        [ SM2DGraphView exposeBinding:@"attributedTitle" ];
        [ SM2DGraphView exposeBinding:@"liveRefresh" ];
    }
}

+ (CGFloat)barWidth
{
    return (CGFloat)10.0;
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [ super initWithFrame:frame ];
    if ( nil != self )
    {	// Initialization code here.
		if ( nil != NSClassFromString( @"NSGarbageCollector" )
					&& [ NSClassFromString( @"NSGarbageCollector" ) defaultCollector] != nil )
		{	// the Garbage Collector is on
			_SM2DGraphView_Private = NSAllocateCollectable( sizeof(SM2DPrivateData), NSScannedOption );
			memset( _SM2DGraphView_Private, 0, sizeof(SM2DPrivateData) );
		}
		else
		{	// retain/release/autorelease/dealloc are being utilized
			_SM2DGraphView_Private = calloc( 1, sizeof(SM2DPrivateData) );
		}
        NSAssert( nil != _SM2DGraphView_Private, NSLocalizedString( @"SM2DGraphView failed private memory allocation",
                    @"SM2DGraphView failed private memory allocation" ) );

        myPrivateData->backgroundColor = [ [ NSColor whiteColor ] copy ];
        myPrivateData->gridColor = [ [ [ NSColor blueColor ] colorWithAlphaComponent:(CGFloat)0.5 ] retain ];
        myPrivateData->borderColor = [ [ NSColor blackColor ] retain ];
        myPrivateData->textAttributes = [ [ NSMutableDictionary dictionaryWithObjectsAndKeys:
                    [ NSFont labelFontOfSize:[ NSFont labelFontSize ] ], NSFontAttributeName,
                    nil ] retain ];
		myPrivateData->title = @"";

        myPrivateData->graphRect = frame;

#if __ppc__
        myPrivateData->flags.useVectorComputation = _sm_local_isAltiVecPresent( );
#else
        myPrivateData->flags.useVectorComputation = NO;
#endif
        myPrivateData->flags.dataSourceIsValid = NO;
        myPrivateData->flags.dataSourceDecidesAttributes = NO;
        myPrivateData->flags.dataSourceWantsDataArray = NO;
        myPrivateData->flags.dataSourceWantsDataChunk = NO;
        myPrivateData->flags.delegateLabelsTickMarks = NO;
        myPrivateData->flags.delegateChangesBarAttrs = NO;
        myPrivateData->flags.delegateWantsMouseDowns = NO;
        myPrivateData->flags.delegateWantsEndDraw = NO;

        [ self _sm_calculateGraphPaperRect ];
        [ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(_sm_frameDidChange:)
                    name:NSViewFrameDidChangeNotification object:self ];
    }
    return self;
}

- (void)dealloc
{
    [ [ NSNotificationCenter defaultCenter ] removeObserver:self ];

	[ myPrivateData->backgroundColor release ];
    [ myPrivateData->gridColor release ];
    [ myPrivateData->borderColor release ];
	[ myPrivateData->title release ];
    [ myPrivateData->lineAttributes release ];
    [ myPrivateData->lineData release ];
    [ myPrivateData->textAttributes release ];
    [ myPrivateData->yAxisInfo.label release ];
    [ myPrivateData->yRightAxisInfo.label release ];
    [ myPrivateData->xAxisInfo.label release ];
    free( _SM2DGraphView_Private );

    [ super dealloc ];
}

#pragma mark -

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    BOOL			tempBool;
    int				tempInt;
    NSDictionary	*dict;
	NSString		*t_string;
    NSUInteger		versionNumber;

    self = [ super initWithCoder:decoder ];

    // Allocate our private memory.
	if ( nil != NSClassFromString( @"NSGarbageCollector" )
				&& [ NSClassFromString( @"NSGarbageCollector" ) defaultCollector] != nil )
	{	// the Garbage Collector is on
		_SM2DGraphView_Private = NSAllocateCollectable( sizeof(SM2DPrivateData), NSScannedOption );
		memset( _SM2DGraphView_Private, 0, sizeof(SM2DPrivateData) );
	}
	else
	{	// retain/release/autorelease/dealloc are being utilized
		_SM2DGraphView_Private = calloc( 1, sizeof(SM2DPrivateData) );
	}
    NSAssert( nil != _SM2DGraphView_Private, NSLocalizedString( @"SM2DGraphView failed private memory allocation",
                @"SM2DGraphView failed private memory allocation" ) );

    // Start filling in objects.
    myPrivateData->backgroundColor = [ [ decoder decodeObject ] copy ];
    myPrivateData->gridColor = [ [ decoder decodeObject ] copy ];

    [ decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool ];
    myPrivateData->flags.drawsGrid = tempBool;

    dict = [ decoder decodeObject ];
    _sm_local_decodeAxisInfo( dict, &myPrivateData->xAxisInfo );

    dict = [ decoder decodeObject ];
    _sm_local_decodeAxisInfo( dict, &myPrivateData->yAxisInfo );

    // Determine version number of encoded class.
    versionNumber = [ decoder versionForClassName:NSStringFromClass( [ SM2DGraphView class ] ) ];

    if ( versionNumber > 0 )
    {
        // This was added in version 1.
        dict = [ decoder decodeObject ];
        _sm_local_decodeAxisInfo( dict, &myPrivateData->yRightAxisInfo );
    }

    if ( versionNumber > 1 )
    {
        // This was added in version 2.
        myPrivateData->borderColor = [ [ decoder decodeObject ] copy ];
    }
    else
        myPrivateData->borderColor = [ [ NSColor blackColor ] retain ];

    if ( versionNumber > 2 )
    {
        // This was added in version 3.
        [ decoder decodeValueOfObjCType:@encode(int) at:&tempInt ];
        myPrivateData->tag = tempInt;
    }

	if ( versionNumber > 3 )
	{	// This was added in version 4.
		t_string = [ decoder decodeObject ];
		myPrivateData->title = [ t_string copy ];
	}
	else
		myPrivateData->title = @"";

    myPrivateData->textAttributes = [ [ NSMutableDictionary dictionaryWithObjectsAndKeys:
                [ NSFont labelFontOfSize:[ NSFont labelFontSize ] ], NSFontAttributeName,
                nil ] retain ];

#if __ppc__
    myPrivateData->flags.useVectorComputation = _sm_local_isAltiVecPresent( );
#else
    myPrivateData->flags.useVectorComputation = NO;
#endif

    myPrivateData->flags.dataSourceIsValid = NO;
    myPrivateData->flags.dataSourceDecidesAttributes = NO;
    myPrivateData->flags.dataSourceWantsDataArray = NO;
    myPrivateData->flags.dataSourceWantsDataChunk = NO;
    myPrivateData->flags.delegateLabelsTickMarks = NO;
    myPrivateData->flags.delegateChangesBarAttrs = NO;
    myPrivateData->flags.delegateWantsMouseDowns = NO;
    myPrivateData->flags.delegateWantsEndDraw = NO;

    [ self _sm_calculateGraphPaperRect ];
    [ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(_sm_frameDidChange:)
                name:NSViewFrameDidChangeNotification object:self ];

    return self;
}

- (void)awakeFromNib
{
    // This is not called in Interface Builder, but it is called when this view has been saved in a nib file
    // and loaded into an application.
    [ self _sm_calculateGraphPaperRect ];

    [ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(_sm_frameDidChange:)
                name:NSViewFrameDidChangeNotification object:self ];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    BOOL			tempBool;
    int				tempInt;
    NSDictionary	*dict;

    [ super encodeWithCoder:coder ];

    // NOTE: The class version number is automatically encoded by Cocoa.

	// Archive our data here.
    [ coder encodeObject:myPrivateData->backgroundColor ];
    [ coder encodeObject:myPrivateData->gridColor ];

    tempBool = myPrivateData->flags.drawsGrid;
    [ coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool ];

    dict = _sm_local_encodeAxisInfo( &myPrivateData->xAxisInfo );
    [ coder encodeObject:dict ];

    dict = _sm_local_encodeAxisInfo( &myPrivateData->yAxisInfo );
    [ coder encodeObject:dict ];

    // Added this in version 1.
    dict = _sm_local_encodeAxisInfo( &myPrivateData->yRightAxisInfo );
    [ coder encodeObject:dict ];

    // Added this in version 2.
    [ coder encodeObject:myPrivateData->borderColor ];

    // Added this in version 3.
    tempInt = myPrivateData->tag;
    [ coder encodeValueOfObjCType:@encode(int) at:&tempInt ];

    // Added this in version 4.
    [ coder encodeObject:myPrivateData->title ];
}

- (Class)valueClassForBinding:(NSString *)binding
{
    Class   result = nil;

    if ( [ binding isEqualToString:@"backgroundColor" ] ||
                [ binding isEqualToString:@"borderColor" ] ||
                [ binding isEqualToString:@"gridColor" ] )
        result = [ NSColor class ];
    else if ( [ binding isEqualToString:@"drawsGrid" ] ||
                [ binding isEqualToString:@"liveRefresh" ] )
        result = [ NSNumber class ];
    else if ( [ binding isEqualToString:@"title" ] )
        result = [ NSString class ];
    else if ( [ binding isEqualToString:@"attributedTitle" ] )
        result = [ NSAttributedString class ];
    else if ( [ [ super class ] instancesRespondToSelector:@selector(valueClassForBinding:) ] )
        result = [ super valueClassForBinding:binding ];

    return result;
}

#pragma mark -

- (void)drawRect:(NSRect)rect
{
    NSUInteger		lineCount, lineIndex, dataCount, dataIndex;
    id				dataObj;
    CGContextRef	context = (CGContextRef) [ NSGraphicsContext currentContext ].graphicsPort ;
#if defined( SM2D_TIMER ) && ( SM2D_TIMER != 0 )
    NSDate			*timer;
    NSTimeInterval	timeInterval;
#endif
    NSPoint			*points = nil;
    NSUInteger		pointsSize = 0;
#if SM2D_USE_CORE_GRAPHICS
#else
    NSBezierPath	*line;
#endif
    NSString		*t_string;
    NSColor			*tempColor = nil;
    NSMutableDictionary *attr;
    NSPoint			*dataLinePoints;
    NSPoint			fromPoint, toPoint;
    NSRect			bounds = self.bounds , graphRect, graphPaperRect, drawRect;
    CGFloat			xScale, minX, yScale, minY;
    NSInteger		i, barNumber;
    BOOL			drawBar;

    graphPaperRect = myPrivateData->graphPaperRect;
    graphRect = myPrivateData->graphRect;

	if ( nil != myPrivateData->title && ((NSString *)myPrivateData->title).length != 0 )
	{
		if ( [ myPrivateData->title isKindOfClass:[ NSAttributedString class ] ] )
			drawRect.size = [ (NSAttributedString *)myPrivateData->title size ];
		else
			drawRect.size = [ (NSString *)myPrivateData->title
						sizeWithAttributes:myPrivateData->textAttributes ];
        drawRect.origin.y = graphPaperRect.origin.y + graphPaperRect.size.height;
        drawRect.origin.x = ( bounds.size.width - drawRect.size.width ) / (CGFloat)2.0;

        if ( NSIntersectsRect( drawRect, rect ) )
        {
			if ( [ myPrivateData->title isKindOfClass:[ NSAttributedString class ] ] )
				[ (NSAttributedString *)myPrivateData->title drawInRect:drawRect ];
			else
				[ myPrivateData->title drawInRect:drawRect
							withAttributes:myPrivateData->textAttributes ];
#if defined( SM_DEBUG_DRAWING ) && ( SM_DEBUG_DRAWING == 1 )
            NSFrameRect( drawRect );
#endif
        }
	}

    if ( nil != [ self labelForAxis:kSM2DGraph_Axis_X ] )
    {
        // Draw the X axis label.
        t_string = [ self labelForAxis:kSM2DGraph_Axis_X ];
        drawRect.size = [ t_string sizeWithAttributes:myPrivateData->textAttributes ];
        drawRect.origin.y = bounds.origin.y;
        drawRect.origin.x = graphRect.origin.x + ( graphRect.size.width - drawRect.size.width ) / (CGFloat)2.0;
        if ( NSIntersectsRect( drawRect, rect ) )
        {
            [ t_string drawInRect:drawRect withAttributes:myPrivateData->textAttributes ];
#if defined( SM_DEBUG_DRAWING ) && ( SM_DEBUG_DRAWING == 1 )
            NSFrameRect( drawRect );
#endif
        }
    }

    for ( i = 0; i < [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_X ]; i++ )
    {
        // Draw the X axis ticks.

        // Figure out the default label.
        if ( myPrivateData->flags.dataSourceIsValid )
        {
            minX = ( [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_X ] -
                        [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_X ] ) *
                        (CGFloat)i / (CGFloat)( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_X ] - 1 );
            minX += [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_X ];
        }
        else
            minX = i;

        t_string = [ NSString stringWithFormat:@"%lg", (double)minX ];

        if ( myPrivateData->flags.delegateLabelsTickMarks )
            t_string = [ [ self delegate ] twoDGraphView:self labelForTickMarkIndex:i forAxis:kSM2DGraph_Axis_X
                        defaultLabel:t_string ];

        if ( nil != t_string )
        {
            drawRect.size = [ t_string sizeWithAttributes:myPrivateData->textAttributes ];
            drawRect.origin.y = bounds.origin.y;
            if ( nil != [ self labelForAxis:kSM2DGraph_Axis_X ] )
                drawRect.origin.y += drawRect.size.height + kSM2DGraph_LabelSpacing;
            drawRect.origin.x = graphRect.origin.x - ( drawRect.size.width / (CGFloat)2.0 ) +
                        ( graphRect.size.width / ( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_X ] - 1 ) ) * i;
            if ( NSIntersectsRect( drawRect, rect ) )
            {
                [ t_string drawInRect:drawRect withAttributes:myPrivateData->textAttributes ];
#if defined( SM_DEBUG_DRAWING ) && ( SM_DEBUG_DRAWING == 1 )
                NSFrameRect( drawRect );
#endif
            }
        }
    }

    if ( nil != [ self labelForAxis:kSM2DGraph_Axis_Y ] )
    {
        // Draw the Y Axis label.
        id		transform;
		//NSAffineTransform	*transform;

        t_string = [ self labelForAxis:kSM2DGraph_Axis_Y ];
        drawRect.size = [ t_string sizeWithAttributes:myPrivateData->textAttributes ];

        // Tip it to draw from bottom to top.
        transform = [ NSClassFromString( @"NSAffineTransform" ) transform ];
        [ (NSAffineTransform *)transform translateXBy:drawRect.size.height yBy:0 ];
        [ (NSAffineTransform *)transform rotateByDegrees:90 ];
        [ (NSAffineTransform *)transform concat ];

        drawRect.origin.y = bounds.origin.y;
        drawRect.origin.x = graphRect.origin.y + ( graphRect.size.height - drawRect.size.width ) / (CGFloat)2.0;
// stub - find a better test...this doesn't seem to work correctly because of the transformations.
//        if ( NSIntersectsRect( drawRect, rect ) )
//        {
            [ t_string drawInRect:drawRect withAttributes:myPrivateData->textAttributes ];
#if defined( SM_DEBUG_DRAWING ) && ( SM_DEBUG_DRAWING == 1 )
            NSFrameRect( drawRect );
#endif
//        }

        [ (NSAffineTransform *)transform invert ];
        [ (NSAffineTransform *)transform concat ];
    }

    for ( i = 0; i < [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_Y ]; i++ )
    {
        // Draw the Y axis ticks.

        // Figure out the default label.
        if ( myPrivateData->flags.dataSourceIsValid )
        {
            minX = ( [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_Y ] -
                        [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_Y ] ) *
                        (CGFloat)i / (CGFloat)( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_Y ] - 1 );
            minX += [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_Y ];
        }
        else
            minX = i;

        t_string = [ NSString stringWithFormat:@"%lg", (double)minX ];

        if ( myPrivateData->flags.delegateLabelsTickMarks )
            t_string = [ [ self delegate ] twoDGraphView:self labelForTickMarkIndex:i forAxis:kSM2DGraph_Axis_Y defaultLabel:t_string ];

        if ( nil != t_string )
        {
            drawRect.size = [ t_string sizeWithAttributes:myPrivateData->textAttributes ];
            drawRect.origin.y = graphRect.origin.y - ( drawRect.size.height / (CGFloat)2.0 ) +
                        ( graphRect.size.height / ( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_Y ] - 1 ) ) * i;
            if ( nil != [ self labelForAxis:kSM2DGraph_Axis_Y ] )
                drawRect.origin.x = ( bounds.origin.x + graphPaperRect.origin.x + drawRect.size.height +
                            kSM2DGraph_LabelSpacing - drawRect.size.width ) / 2;
            else
                drawRect.origin.x = ( bounds.origin.x + graphPaperRect.origin.x - drawRect.size.width ) / 2;
            if ( NSIntersectsRect( drawRect, rect ) )
            {
                [ t_string drawInRect:drawRect withAttributes:myPrivateData->textAttributes ];
#if defined( SM_DEBUG_DRAWING ) && ( SM_DEBUG_DRAWING == 1 )
                NSFrameRect( drawRect );
#endif
            }
        }
    }

    if ( nil != [ self labelForAxis:kSM2DGraph_Axis_Y_Right ] )
    {
        // Draw the Y Axis right side label.
		id		transform;
		//NSAffineTransform	*transform;

        t_string = [ self labelForAxis:kSM2DGraph_Axis_Y_Right ];
        drawRect.size = [ t_string sizeWithAttributes:myPrivateData->textAttributes ];

        // Tip it to draw from top to bottom.
        transform = [ NSClassFromString( @"NSAffineTransform" ) transform ];
        [ transform translateXBy:bounds.size.width - drawRect.size.height yBy:bounds.size.height ];
        [ transform rotateByDegrees:(CGFloat)-90 ];
        [ transform concat ];

        drawRect.origin.y = bounds.origin.y;
        drawRect.origin.x = ( bounds.size.height - graphRect.origin.y - graphRect.size.height ) +
                    ( graphRect.size.height - drawRect.size.width ) / (CGFloat)2.0;
// stub - find a better test...this doesn't seem to work correctly because of the transformations.
//        if ( NSIntersectsRect( drawRect, rect ) )
//        {
            [ t_string drawInRect:drawRect withAttributes:myPrivateData->textAttributes ];
#if defined( SM_DEBUG_DRAWING ) && ( SM_DEBUG_DRAWING == 1 )
            NSFrameRect( drawRect );
#endif
//        }

        [ transform invert ];
        [ transform concat ];
    }

    for ( i = 0; i < [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_Y_Right ]; i++ )
    {
        // Draw the Y axis right side ticks.

        // Figure out the default label.
        if ( myPrivateData->flags.dataSourceIsValid )
        {
            minX = ( [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:0
                        forAxis:kSM2DGraph_Axis_Y_Right ] - [ [ self dataSource ] twoDGraphView:self
                        minimumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_Y_Right ] ) * (CGFloat)i /
                        (CGFloat)( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_Y_Right ] - 1 );
            minX += [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:0
                        forAxis:kSM2DGraph_Axis_Y_Right ];
        }
        else
            minX = i;

        t_string = [ NSString stringWithFormat:@"%lg", (double)minX ];

        if ( myPrivateData->flags.delegateLabelsTickMarks )
            t_string = [ [ self delegate ] twoDGraphView:self labelForTickMarkIndex:i forAxis:kSM2DGraph_Axis_Y_Right
                        defaultLabel:t_string ];

        if ( nil != t_string )
        {
            drawRect.size = [ t_string sizeWithAttributes:myPrivateData->textAttributes ];
            drawRect.origin.y = graphRect.origin.y - ( drawRect.size.height / (CGFloat)2.0 ) +
                        ( graphRect.size.height / ( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_Y_Right ] - 1 ) ) *
                        i;
            drawRect.origin.x = graphPaperRect.origin.x + graphPaperRect.size.width + kSM2DGraph_LabelSpacing;
            if ( NSIntersectsRect( drawRect, rect ) )
            {
                [ t_string drawInRect:drawRect withAttributes:myPrivateData->textAttributes ];
#if defined( SM_DEBUG_DRAWING ) && ( SM_DEBUG_DRAWING == 1 )
                NSFrameRect( drawRect );
#endif
            }
        }
    }

    if ( NSIntersectsRect( graphPaperRect, rect ) )
    {
        // Draw the background of the graph paper.
        if ( nil != myPrivateData->backgroundColor )
        {
            [ myPrivateData->backgroundColor set ];
            NSRectFill( graphPaperRect );
        }

        // Frame it in the border color.
        [ [ self borderColor ] set ];
        NSFrameRect( graphPaperRect );

        // Possibly draw the grid on the graph paper.
        if ( [ self drawsGrid ] )
            [ self _sm_drawGridInRect:rect ];

        if ( [ self drawsLineAtZeroForAxis:kSM2DGraph_Axis_Y ] && myPrivateData->flags.dataSourceIsValid && 
                    [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_Y ] > (CGFloat)0.0 &&
                    [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_Y ] < (CGFloat)0.0 )
        {
            // Need to draw a horizontal line through zero since it's on the graph and not at the max or minimum.
            fromPoint.x = graphPaperRect.origin.x;
            toPoint.x = graphPaperRect.origin.x + graphPaperRect.size.width;

            minY = [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_Y ];
            yScale = [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_Y ]
                        - minY;
            yScale = ( graphRect.size.height - (CGFloat)2.0 ) / yScale;

            toPoint.y = fromPoint.y = ( (CGFloat)0.0 - minY ) * yScale + graphRect.origin.y + (CGFloat)1.0;

            [ [ [ NSColor blackColor ] colorWithAlphaComponent:(CGFloat)0.6 ] set ];
            [ NSBezierPath strokeLineFromPoint:fromPoint toPoint:toPoint ];
        }

        if ( [ self drawsLineAtZeroForAxis:kSM2DGraph_Axis_X ] && myPrivateData->flags.dataSourceIsValid &&
                    [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_X ] > (CGFloat)0.0 &&
                    [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_X ] < (CGFloat)0.0 )
        {
            // Need to draw a vertical line through zero since it's on the graph and not at the max or minimum.
            fromPoint.y = graphPaperRect.origin.y;
            toPoint.y = graphPaperRect.origin.y + graphPaperRect.size.height;

            minX = [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_X ];
            xScale = [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_X ]
                        - minX;
            xScale = ( graphRect.size.width - (CGFloat)2.0 ) / xScale;

            toPoint.x = fromPoint.x = ( (CGFloat)0.0 - minX ) * xScale + graphRect.origin.x + (CGFloat)1.0;

            [ [ [ NSColor blackColor ] colorWithAlphaComponent:(CGFloat)0.6 ] set ];
            [ NSBezierPath strokeLineFromPoint:fromPoint toPoint:toPoint ];
        }

        if ( nil != myPrivateData->lineData && myPrivateData->lineData.count > 0
                    && ! self.inLiveResize )
        {
#if defined( SM2D_TIMER ) && ( SM2D_TIMER == 1 )
            timer = [ NSDate date ];
#endif

            // Draw the data (but not when we're in a live resize).
            [ NSBezierPath clipRect:NSInsetRect( graphPaperRect, (CGFloat)1.0, (CGFloat)1.0 ) ];

            lineCount = myPrivateData->lineData.count ;
            barNumber = 0;
            for ( lineIndex = 0; lineIndex < lineCount; lineIndex++ )
            {
                dataObj = myPrivateData->lineData[lineIndex];
                if ( [ dataObj isKindOfClass:[ NSArray class ] ] )
                {
                    dataCount = ((NSArray *)dataObj).count ;
                    dataLinePoints = nil;
                }
                else
                {
                    dataCount = ((NSData *)dataObj).length / sizeof(NSPoint);
                    dataLinePoints = (NSPoint *)[ dataObj bytes ];
                }

                // Calculate the minimum X value and the X scale.
                minX = [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:lineIndex
                            forAxis:kSM2DGraph_Axis_X ];
                xScale = [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:lineIndex
                            forAxis:kSM2DGraph_Axis_X ] - minX;
				//if ( 0 == (NSInteger)xScale )
				if ( CGFloatAbs(xScale) < SM2D_EPSILON )
				{
					NSLog( @"SM2DGraphView: min and max X values for line index: %ld are both equal to: %lg",
								(long)lineIndex, (double)minX );
					continue;	// Try moving on to the next line.
				}
                xScale = ( graphRect.size.width - (CGFloat)1.0 ) / xScale;

                // Calculate the minimum Y value and the Y scale.
                minY = [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:lineIndex
                            forAxis:kSM2DGraph_Axis_Y ];
                yScale = [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:lineIndex
                            forAxis:kSM2DGraph_Axis_Y ]
                            - minY;
				//if ( 0 == yScale )
				if ( CGFloatAbs(yScale) < SM2D_EPSILON )
				{
					NSLog( @"SM2DGraphView: min and max Y values for line index: %ld are both equal to: %lg",
								(long)lineIndex, (double)minY );
					continue;	// Try moving on to the next line.
				}
                yScale = ( graphRect.size.height - (CGFloat)2.0 ) / yScale;


                // Allocate memory for the scaled data points.
                if ( (sizeof(NSPoint) * dataCount) > pointsSize )
                {
                    pointsSize = sizeof(NSPoint) * dataCount;
                    if ( nil != points )
                        free( points );
                    points = malloc( pointsSize );
                }

                // First, just copy all of the data points into a local array.
                if ( nil != dataLinePoints )
                    memcpy( points, dataLinePoints, sizeof(NSPoint) * dataCount );
                else
                {
                    // Get the values out of the string and into an array of NSPoints.
                    for ( dataIndex = 0; dataIndex < dataCount; dataIndex++ )
                        points[ dataIndex ] = NSPointFromString( ((NSArray *)dataObj)[dataIndex] );
                }

#if defined( SM2D_TIMER ) && ( SM2D_TIMER == 2 )
                timer = [ NSDate date ];
#endif

#if __ppc__
                if ( myPrivateData->flags.useVectorComputation && 63 < dataCount )
                    // If CPU has Velocity Engine and we have at least 64 data points, we'll use V.E.
                    // Doesn't really make sense to use it for small data sets because the setup time can be big.
                    // 64 data points is 32 passes through the inner loop for V.E. (two points at a time for V.E.)
                    _sm_local_scaleDataUsingVelocityEngine( points, dataCount,
                                minX, xScale, graphRect.origin.x + (CGFloat)1.0,
                                minY, yScale, graphRect.origin.y + (CGFloat)1.0 );
                else
#endif // __ppc__

                {
                    // Scale the points using the CPU as normal.
                    for ( dataIndex = 0; dataIndex < dataCount; dataIndex++ )
                    {
                        // Scale the data point into the graphRect correctly.
                        points[ dataIndex ].x = ( points[ dataIndex ].x - minX ) * xScale + graphRect.origin.x + (CGFloat)1.0;
                        points[ dataIndex ].y = ( points[ dataIndex ].y - minY ) * yScale + graphRect.origin.y + (CGFloat)1.0;
                    }
                }

#if defined( SM2D_TIMER ) && ( SM2D_TIMER == 2 )
                timeInterval = [ timer timeIntervalSinceNow ];
                NSLog( @"SM2DGraphView: Scaling %ld points took %lg microseconds", (long)dataCount, (double)-timeInterval * (double)1000000 );
#endif

#if !SM2D_USE_CORE_GRAPHICS
                line = nil;
#endif
                drawBar =  ( nil != myPrivateData->lineAttributes[lineIndex][SM2DGraphBarStyleAttributeName] );
                if ( drawBar )
                {
                    // If we're drawing a bar graph, that's a simple loop and draw each bar.
                    barNumber++;
                    tempColor = myPrivateData->lineAttributes[lineIndex][NSForegroundColorAttributeName];
                    if ( tempColor == nil )
                        tempColor = [ NSColor blackColor ];

                    attr = [ NSMutableDictionary dictionaryWithObject:tempColor
                                forKey:NSForegroundColorAttributeName ];

                    // Draw all bars starting at the zero vertical location...
                    fromPoint.y = ( (CGFloat)0.0 - minY ) * yScale + graphRect.origin.y + (CGFloat)1.0;
                    fromPoint.y = CGFloatFloor( fromPoint.y + (CGFloat)0.5 );	// Make it an integer.

                    // Limit the bars to actually draw inside the graph area.
                    if ( fromPoint.y < graphRect.origin.y + (CGFloat)1.0 )
                        fromPoint.y = graphRect.origin.y + (CGFloat)1.0;
                    else if ( fromPoint.y > graphRect.origin.y + graphRect.size.height - 1 )
                        fromPoint.y = graphRect.origin.y + graphRect.size.height - 1;

                    for ( dataIndex = 0; dataIndex < dataCount; dataIndex++ )
                    {
                        fromPoint.x = points[ dataIndex ].x;

                        if ( myPrivateData->flags.delegateChangesBarAttrs )
                        {
                            [ delegate twoDGraphView:self willDisplayBarIndex:dataIndex forLineIndex:lineIndex
                                        withAttributes:attr ];
                            tempColor = attr[NSForegroundColorAttributeName];
                            if ( tempColor == nil )
                                tempColor = [ NSColor blackColor ];
                        }

                        [ self _sm_drawVertBarFromPoint:fromPoint toPoint:points[ dataIndex ] barNumber:barNumber
                                    of:myPrivateData->barCount inColor:tempColor ];
                    }
                }
#if !SM2D_USE_CORE_GRAPHICS
                else
                {
                    // We're not drawing a bar.  We're drawing a line (or symbols only).
                    // Since we're not using Core Graphics, we'll make the data points into an NSBezierPath.
                    for ( dataIndex = 0; dataIndex < dataCount; dataIndex++ )
                    {
                        if ( 0 == dataIndex )
                        {
                            // Start a new NSBezierPath with a -moveToPoint;
                            line = [ NSBezierPath bezierPath ];
                            [ line moveToPoint:points[ dataIndex ] ];
                        }
                        else
                            // All others are -lineToPoint;
                            [ line lineToPoint:points[ dataIndex ] ];
                    }
                }
#endif

#if SM2D_USE_CORE_GRAPHICS
                if ( nil != points && !drawBar && 0 < dataCount )
#else
                if ( nil != line )
#endif
                {
                    NSNumber	*tempNumber = nil;
                    BOOL		tempBool = YES;

                    // Possibly turn off anti-aliasing for this line.
                    CGContextSetShouldAntialias( context, ( nil == myPrivateData->lineAttributes[lineIndex][SM2DGraphDontAntialiasAttributeName] ) );

                    tempNumber = myPrivateData->lineAttributes[lineIndex][SM2DGraphLineWidthAttributeName];

                    if ( nil != tempNumber )
                    {
                        switch ( tempNumber.intValue )
                        {
                        case kSM2DGraph_Width_Fine:
#if SM2D_USE_CORE_GRAPHICS
                            CGContextSetLineWidth( context, (CGFloat)0.5 );
#else
                            line.lineWidth = (CGFloat)0.5 ;
#endif
                            break;
                        case kSM2DGraph_Width_Wide:
#if SM2D_USE_CORE_GRAPHICS
                            CGContextSetLineWidth( context, (CGFloat)2.0 );
#else
                            line.lineWidth = (CGFloat)2.0 ;
#endif
                            break;
                        case kSM2DGraph_Width_None:
                            tempBool = NO;
                            break;
                        default:
#if SM2D_USE_CORE_GRAPHICS
                            CGContextSetLineWidth( context, (CGFloat)1.0 );
#else
                            line.lineWidth = (CGFloat)1.0 ;
#endif
                            break;
                        }
                    }

					tempNumber = myPrivateData->lineAttributes[lineIndex][SM2DGraphLineDashAttributeName];

					if ( nil != tempNumber )
					{
						CGFloat lengths[4] = {1.0, 0.0, 1.0, 0.0};
						const CGFloat smallStep = 8.0;
						const CGFloat largeStep = 16.0;

						switch ( tempNumber.intValue )
						{
						case kSM2DGraph_Dash_Small:
							lengths[0] = lengths[1] = lengths[2] = lengths[3] = smallStep;
							break;
						case kSM2DGraph_Dash_Large:
							lengths[0] = lengths[2] = largeStep;
							lengths[1] = lengths[3] = smallStep;
							break;
						case kSM2DGraph_Dash_Mixed:
							lengths[0] = largeStep;
							lengths[1] = lengths[2] = lengths[3] = smallStep;
							break;
						}
						if ( tempNumber.intValue != kSM2DGraph_Dash_None )
						{
#if SM2D_USE_CORE_GRAPHICS
							CGContextSetLineDash( context, 0.0, lengths, 4 );
#else
							[ line setLineDash:lengths count:4 phase:0.0 ];
#endif
						}
					}

                    // Go ahead and draw the line as an NSBezierPath.
                    tempColor = myPrivateData->lineAttributes[lineIndex][NSForegroundColorAttributeName];
                    if ( nil != tempColor )
                        [ tempColor set ];
                    else
                        [ [ NSColor blackColor ] set ];

                    if ( tempBool )
                    {
#if SM2D_USE_CORE_GRAPHICS
                        // Add the points to the current path and stroke it.
                        // NOTE: stroking a path also clears the path (thus we need to store the path for later use).
                        // NOTE: CGPoint == NSPoint.
                        CGContextAddLines( context, (CGPoint *)points, dataCount );
                        CGContextStrokePath( context );
#else
                        [ line stroke ];
#endif

                        if ( nil == tempNumber || kSM2DGraph_Width_3D == tempNumber.intValue )
                        {
#if !SM2D_USE_CORE_GRAPHICS
                            id	offsetUp = [ NSClassFromString( @"NSAffineTransform" ) transform ];
                            id	offsetDown = [ NSClassFromString( @"NSAffineTransform" ) transform ];
#endif

                            // Make a lighter color above it.
                            if ( nil != tempColor )
                                [ [ tempColor blendedColorWithFraction:(CGFloat)0.3 ofColor:[ NSColor whiteColor ] ] set ];
#if SM2D_USE_CORE_GRAPHICS
                            CGContextTranslateCTM( context, (CGFloat)0.0, (CGFloat)1.0 );
                            CGContextAddLines( context, (CGPoint *)points, dataCount );
                            CGContextStrokePath( context );
#else
                            [ offsetUp translateXBy:(CGFloat)0.0 yBy:(CGFloat)1.0 ];
                            [ offsetDown translateXBy:(CGFloat)0.0 yBy:(CGFloat)-1.0 ];

                            [ line transformUsingAffineTransform:offsetUp ];
                            [ line stroke ];
#endif

                            // Make a darker color below it.
                            if ( nil != tempColor )
                                [ [ tempColor blendedColorWithFraction:(CGFloat)0.3 ofColor:[ NSColor blackColor ] ] set ];
#if SM2D_USE_CORE_GRAPHICS
                            CGContextTranslateCTM( context, (CGFloat)0.0, (CGFloat)-2.0 );
                            CGContextAddLines( context, (CGPoint *)points, dataCount );
                            CGContextStrokePath( context );
                            CGContextTranslateCTM( context, (CGFloat)0.0, (CGFloat)1.0 );
#else
                            [ line transformUsingAffineTransform:offsetDown ];
                            [ line transformUsingAffineTransform:offsetDown ];
                            [ line stroke ];
                            [ line transformUsingAffineTransform:offsetUp ];
#endif
                        } // if line width is "normal" - 3 pixels wide
                    } // if line width is not "none".

                    // Make sure antialiasing is on.
                    CGContextSetShouldAntialias( context, YES );

                    // Possibly draw symbols on the line.
                    tempNumber = myPrivateData->lineAttributes[lineIndex][SM2DGraphLineSymbolAttributeName];
#if SM2D_USE_CORE_GRAPHICS
                    if ( nil != tempNumber && [ tempNumber intValue ] != kSM2DGraph_Symbol_None )
                        [ self _sm_drawSymbol:[ tempNumber intValue ] onLine:points
						count:dataCount
                                    inColor:tempColor
									inRect:rect
									 ];

//                    free( points );
//                    points = nil;
#else
                    if ( nil != tempNumber && tempNumber.intValue != kSM2DGraph_Symbol_None )
                        [ self _sm_drawSymbol: tempNumber.intValue onLine:line inColor:tempColor inRect:rect ];
#endif
                } // if bezier path ( line != nil ) or ( points != nil )

                // Signal the delegate that we're done.
                if ( myPrivateData->flags.delegateWantsEndDraw )
                    [ [ self delegate ] twoDGraphView:self doneDrawingLineIndex:lineIndex ];
            } // end of this line.

            if ( nil != points )
                free( points );
#if defined( SM2D_TIMER ) && ( SM2D_TIMER == 1 )
            timeInterval = [ timer timeIntervalSinceNow ];
            NSLog( @"SM2DGraphView: drawing all lines took this long: %lg", (double)-timeInterval );
#endif
        } // end have to draw our lines.
    }
}

- (void)viewDidEndLiveResize
{
    // Make sure we redisplay so the data lines show up in the graph.
    [ super viewDidEndLiveResize ];
    [ self setNeedsDisplay:YES ];
}

- (void)mouseDown:(NSEvent *)inEvent
{
    if ( myPrivateData->flags.delegateWantsMouseDowns )
    {
        NSPoint		curPoint;

        curPoint = [ self convertPoint: inEvent.locationInWindow fromView:nil ];

        // Do we want to track until mouse up and THEN call the delegate?
        [ [ self delegate ] twoDGraphView:self didClickPoint:curPoint ];
    }
    else
        [ super mouseDown:inEvent ];
}

- (void)print:(id)sender
{
	NSPrintInfo		*print_info;

	// Set the pagination so that we will be scaled down to fit on a page if necessary.
	print_info = [ NSPrintInfo sharedPrintInfo ];
	print_info.horizontalPagination = NSFitPagination ;
	print_info.verticalPagination = NSFitPagination ;

	[ [ NSPrintOperation printOperationWithView:self printInfo:print_info ] runOperation ];
}

#pragma mark -
#pragma mark • ACCESSORS

- (void)setDataSource:(id)inDataSource
{
    BOOL	failed = NO;

	dataSource = inDataSource;

    // Assert some checks on the data source.
    if ( ![ dataSource respondsToSelector:@selector(numberOfLinesInTwoDGraphView:) ] )
    {
        failed = YES;
        NSLog( @"SM2DGraphView data source does not respond to selector -numberOfLinesInTwoDGraphView:" );
    }
    if ( ![ dataSource respondsToSelector:@selector(twoDGraphView:dataForLineIndex:) ] &&
                ![ dataSource respondsToSelector:@selector(twoDGraphView:dataObjectForLineIndex:) ] )
    {
        failed = YES;
        NSLog( @"SM2DGraphView data source does not respond to selector -twoDGraphView:dataForLineIndex: or twoDGraphView:dataObjectForLineIndex:" );
    }
    if ( ![ dataSource respondsToSelector:@selector(twoDGraphView:maximumValueForLineIndex:forAxis:) ] )
    {
        failed = YES;
        NSLog( @"SM2DGraphView data source does not respond to selector -twoDGraphView:maximumValueForLineIndex:forAxis:" );
    }
    if ( ![ dataSource respondsToSelector:@selector(twoDGraphView:minimumValueForLineIndex:forAxis:) ] )
    {
        failed = YES;
        NSLog( @"SM2DGraphView data source does not respond to selector -twoDGraphView:minimumValueForLineIndex:forAxis:" );
    }

    myPrivateData->flags.dataSourceIsValid = !failed;

    // Check for optional methods.
    myPrivateData->flags.dataSourceDecidesAttributes = [ dataSource
                respondsToSelector:@selector(twoDGraphView:attributesForLineIndex:) ];

    myPrivateData->flags.dataSourceWantsDataArray = [ dataSource
                respondsToSelector:@selector(twoDGraphView:dataForLineIndex:) ];
    myPrivateData->flags.dataSourceWantsDataChunk = [ dataSource
                respondsToSelector:@selector(twoDGraphView:dataObjectForLineIndex:) ];
}

- (id)dataSource
{	return dataSource;	}

- (void)setDelegate:(id)inDelegate
{
    delegate = inDelegate;

    myPrivateData->flags.delegateLabelsTickMarks = [ delegate
                respondsToSelector:@selector(twoDGraphView:labelForTickMarkIndex:forAxis:defaultLabel:) ];

    myPrivateData->flags.delegateChangesBarAttrs = [ delegate
                respondsToSelector:@selector(twoDGraphView:willDisplayBarIndex:forLineIndex:withAttributes:) ];

    myPrivateData->flags.delegateWantsMouseDowns = [ delegate
                respondsToSelector:@selector(twoDGraphView:didClickPoint:) ];

    myPrivateData->flags.delegateWantsEndDraw = [ delegate
                respondsToSelector:@selector(twoDGraphView:doneDrawingLineIndex:) ];
}

- (id)delegate
{	return delegate;	}

- (void)setTag:(NSInteger)inTag
{	myPrivateData->tag = inTag;	}

- (NSInteger)tag
{	return myPrivateData->tag;	}

- (void)setLiveRefresh:(BOOL)inFlag
{
	myPrivateData->flags.liveRefresh = inFlag;
}

- (BOOL)liveRefresh
{
	return myPrivateData->flags.liveRefresh;
}

- (void)setDrawsGrid:(BOOL)inFlag
{
	myPrivateData->flags.drawsGrid = inFlag;
    [ self setNeedsDisplay:YES ];
}

- (BOOL)drawsGrid
{	return myPrivateData->flags.drawsGrid;	}

- (void)setBackgroundColor:(NSColor *)inColor
{
	[ myPrivateData->backgroundColor release ];
    myPrivateData->backgroundColor = [ inColor copy ];
    [ self setNeedsDisplay:YES ];
}

- (NSColor *)backgroundColor
{	return [ [ myPrivateData->backgroundColor retain ] autorelease ];	}

- (void)setGridColor:(NSColor *)inColor
{
	[ myPrivateData->gridColor release ];
    myPrivateData->gridColor = [ inColor copy ];
    [ self setNeedsDisplay:YES ];
}

- (NSColor *)gridColor
{	return [ [ myPrivateData->gridColor retain ] autorelease ];	}

- (void)setBorderColor:(NSColor *)inColor
{
	[ myPrivateData->borderColor release ];
    myPrivateData->borderColor = [ inColor copy ];
    [ self setNeedsDisplay:YES ];
}

- (NSColor *)borderColor
{	return [ [ myPrivateData->borderColor retain ] autorelease ];	}

- (void)setTitle:(NSString *)inTitle
{	[ myPrivateData->title release ];
    myPrivateData->title = [ inTitle copy ];
	[ self _sm_calculateGraphPaperRect ];
    [ self setNeedsDisplay:YES ];
}

- (NSString *)title
{	return [ [ myPrivateData->title retain ] autorelease ];	}

- (void)setAttributedTitle:(NSAttributedString *)inTitle
{	[ myPrivateData->title release ];
    myPrivateData->title = [ inTitle copy ];
	[ self _sm_calculateGraphPaperRect ];
    [ self setNeedsDisplay:YES ];
}

- (NSAttributedString *)attributedTitle
{	return [ [ myPrivateData->title retain ] autorelease ];	}

- (void)setLabel:(NSString *)inNewLabel forAxis:(SM2DGraphAxisEnum)inAxis
{
    SM2DGraphAxisRecord	*info;

    info = _sm_local_determineAxis( inAxis, myPrivateData );

    if ( info->label != inNewLabel )
    {
        [ info->label release ];
        info->label = [ inNewLabel copy ];
        [ self _sm_calculateGraphPaperRect ];
        [ self setNeedsDisplay:YES ];
    }
}

- (NSString *)labelForAxis:(SM2DGraphAxisEnum)inAxis
{
    SM2DGraphAxisRecord	*info;

    info = _sm_local_determineAxis( inAxis, myPrivateData );

    return [ [ info->label retain ] autorelease ];
}

- (void)setNumberOfTickMarks:(NSInteger)count forAxis:(SM2DGraphAxisEnum)inAxis
{
    SM2DGraphAxisRecord	*info;

    info = _sm_local_determineAxis( inAxis, myPrivateData );

    if ( info->numberOfTickMarks != count )
    {
        info->numberOfTickMarks = count;
        [ self _sm_calculateGraphPaperRect ];
        [ self setNeedsDisplay:YES ];
    }
}

- (NSInteger)numberOfTickMarksForAxis:(SM2DGraphAxisEnum)inAxis
{    SM2DGraphAxisRecord	*info;

    info = _sm_local_determineAxis( inAxis, myPrivateData );

	return info->numberOfTickMarks;
}

- (void)setNumberOfMinorTickMarks:(NSInteger)count forAxis:(SM2DGraphAxisEnum)inAxis
{
    SM2DGraphAxisRecord	*info;

    info = _sm_local_determineAxis( inAxis, myPrivateData );

    if ( info->numberOfMinorTickMarks != count )
    {
        info->numberOfMinorTickMarks = count;
        [ self setNeedsDisplay:YES ];
    }
}

- (NSInteger)numberOfMinorTickMarksForAxis:(SM2DGraphAxisEnum)inAxis
{    SM2DGraphAxisRecord	*info;

    info = _sm_local_determineAxis( inAxis, myPrivateData );

	return info->numberOfMinorTickMarks;
}

- (void)setTickMarkPosition:(NSTickMarkPosition)position forAxis:(SM2DGraphAxisEnum)inAxis
{
    SM2DGraphAxisRecord	*info;

    info = _sm_local_determineAxis( inAxis, myPrivateData );

    if ( info->tickMarkPosition != position )
    {
        info->tickMarkPosition = position;
        NSLog( @"SM2DGraphView: Tick mark positions are currently unimplemented" );
// stub - implement this to actually do something.
//        [ self _sm_calculateGraphPaperRect ];
//        [ self setNeedsDisplay:YES ];
    }
}

- (NSTickMarkPosition)tickMarkPositionForAxis:(SM2DGraphAxisEnum)inAxis
{    SM2DGraphAxisRecord	*info;

    info = _sm_local_determineAxis( inAxis, myPrivateData );

	return info->tickMarkPosition;
}

/*- (void)setScaleType:(SM2DGraphScaleTypeEnum)inNewValue forAxis:(SM2DGraphAxisEnum)inAxis
{
    SM2DGraphAxisRecord	*info;

    info = _sm_local_determineAxis( inAxis, myPrivateData );

    if ( info->scaleType != inNewValue )
    {
        info->scaleType = inNewValue;
        [ self _sm_calculateGraphPaperRect ];
        [ self setNeedsDisplay:YES ];
    }
}

- (SM2DGraphScaleTypeEnum)scaleTypeForAxis:(SM2DGraphAxisEnum)inAxis
{    SM2DGraphAxisRecord	*info;

    info = _sm_local_determineAxis( inAxis, myPrivateData );

	return info->scaleType;
}*/

- (void)setAxisInset:(CGFloat)inInset forAxis:(SM2DGraphAxisEnum)inAxis
{
    SM2DGraphAxisRecord	*info;

    info = _sm_local_determineAxis( inAxis, myPrivateData );

   // if ( info->inset != inInset ) DFH
    if ( CGFloatAbs(info->inset - inInset) >= SM2D_EPSILON)
    {
        info->inset = inInset;
        [ self _sm_calculateGraphPaperRect ];
        [ self setNeedsDisplay:YES ];
    }
}

- (CGFloat)axisInsetForAxis:(SM2DGraphAxisEnum)inAxis
{    SM2DGraphAxisRecord	*info;

    info = _sm_local_determineAxis( inAxis, myPrivateData );

	return info->inset;
}

- (void)setDrawsLineAtZero:(BOOL)inNewValue forAxis:(SM2DGraphAxisEnum)inAxis
{
    SM2DGraphAxisRecord	*info;

    info = _sm_local_determineAxis( inAxis, myPrivateData );

    if ( info->drawLineAtZero != inNewValue )
    {
        info->drawLineAtZero = inNewValue;
        [ self setNeedsDisplay:YES ];
    }
}

- (BOOL)drawsLineAtZeroForAxis:(SM2DGraphAxisEnum)inAxis
{    SM2DGraphAxisRecord	*info;

    info = _sm_local_determineAxis( inAxis, myPrivateData );

	return info->drawLineAtZero;
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
    NSUInteger	numLines, i;
    id			lineData;

    if ( myPrivateData->flags.dataSourceIsValid )
    {
        numLines = [ [ self dataSource ] numberOfLinesInTwoDGraphView:self ];

        [ myPrivateData->lineData release ];
        myPrivateData->lineData = [ [ NSMutableArray arrayWithCapacity:numLines ] retain ];

        for ( i = 0; i < numLines; i++ )
        {
            lineData = nil;
            if ( myPrivateData->flags.dataSourceWantsDataChunk )
            {
                // Try grabbing an NSData chunk.
                lineData = [ [ self dataSource ] twoDGraphView:self dataObjectForLineIndex:i ];
                if ( nil == lineData && myPrivateData->flags.dataSourceWantsDataArray )
                    // Otherwise grab an NSArray.
                    lineData = [ [ self dataSource ] twoDGraphView:self dataForLineIndex:i ];
            }
            else if ( myPrivateData->flags.dataSourceWantsDataArray )
                // Don't want NSData chunks...grab an NSArray.
                lineData = [ [ self dataSource ] twoDGraphView:self dataForLineIndex:i ];

            if ( lineData == nil )
                // Didn't get anything...make it into an NSMutableData for speed purposes.
                lineData = [ NSMutableData dataWithLength:0 ];

            [ myPrivateData->lineData addObject:lineData ];
        }

        [ self _sm_calculateGraphPaperRect ];

        [ self setNeedsDisplay:YES ];
    }
}

- (void)reloadDataForLineIndex:(NSUInteger)inLineIndex
{
    id		lineData = nil;

    if ( myPrivateData->flags.dataSourceIsValid )
    {
        if ( myPrivateData->flags.dataSourceWantsDataChunk )
        {
            // Try grabbing an NSData chunk.
            lineData = [ [ self dataSource ] twoDGraphView:self dataObjectForLineIndex:inLineIndex ];
            if ( nil == lineData && myPrivateData->flags.dataSourceWantsDataArray )
                // Otherwise grab an NSArray.
                lineData = [ [ self dataSource ] twoDGraphView:self dataForLineIndex:inLineIndex ];
        }
        else if ( myPrivateData->flags.dataSourceWantsDataArray )
            // Don't want NSData chunks...grab an NSArray.
            lineData = [ [ self dataSource ] twoDGraphView:self dataForLineIndex:inLineIndex ];

        if ( lineData == nil )
            // Didn't get anything...make it into an NSMutableData for speed purposes.
            lineData = [ NSMutableData dataWithLength:0 ];

        myPrivateData->lineData[inLineIndex] = lineData;

        [ self _sm_calculateGraphPaperRect ];
        [ self setNeedsDisplay:YES ];
    }
}

- (void)reloadAttributes
{
    NSUInteger	numLines, i;
    NSDictionary	*lineData;

    numLines = [ [ self dataSource ] numberOfLinesInTwoDGraphView:self ];
    [ myPrivateData->lineAttributes release ];
    myPrivateData->lineAttributes = [ [ NSMutableArray arrayWithCapacity:numLines ] retain ];
    myPrivateData->barCount = 0;

    if ( myPrivateData->flags.dataSourceDecidesAttributes )
    {
        for ( i = 0; i < numLines; i++ )
        {
            lineData = [ [ self dataSource ] twoDGraphView:self attributesForLineIndex:i ];
            if ( nil == lineData )
                lineData = _sm_local_defaultLineAttributes( i );
            [ myPrivateData->lineAttributes addObject:lineData ];

            // Count the number of bars to show.
            if ( nil != lineData[SM2DGraphBarStyleAttributeName] )
                myPrivateData->barCount++;
        }
    }
    else
    {
        for ( i = 0; i < numLines; i++ )
        {
            lineData = _sm_local_defaultLineAttributes( i );
            [ myPrivateData->lineAttributes addObject:lineData ];

            // Count the number of bars to show.
            if ( nil != lineData[SM2DGraphBarStyleAttributeName] )
                myPrivateData->barCount++;
        }
    }

    [ self _sm_calculateGraphPaperRect ];
    [ self setNeedsDisplay:YES ];
}

- (void)reloadAttributesForLineIndex:(NSUInteger)inLineIndex
{
    NSDictionary	*lineData, *replacingData;
    BOOL			wasBar;

    // Determine if the attribute being replaced was a bar or not (so we can keep the bar count correct).
    replacingData = myPrivateData->lineAttributes[inLineIndex];
    wasBar = ( nil != replacingData[SM2DGraphBarStyleAttributeName] );

    if ( myPrivateData->flags.dataSourceDecidesAttributes )
    {
        // Let the dataSource object figure it out.
        lineData = [ [ self dataSource ] twoDGraphView:self attributesForLineIndex:inLineIndex ];
        if ( nil == lineData )
            lineData = _sm_local_defaultLineAttributes( inLineIndex );
    }
    else
        lineData = _sm_local_defaultLineAttributes( inLineIndex );

    myPrivateData->lineAttributes[inLineIndex] = lineData;

    // Count the number of bars to show.
    if ( nil != lineData[SM2DGraphBarStyleAttributeName] )
    {
        // New line attribute is a bar...
        if ( !wasBar )
            // ...old line was NOT a bar; added a bar.
            myPrivateData->barCount++;
    }
    else
    {
        // New line attribute is NOT a bar...
        if ( wasBar )
            // ...old line was a bar; removed a bar.
            myPrivateData->barCount--;
    }

    [ self _sm_calculateGraphPaperRect ];
    [ self setNeedsDisplay:YES ];
}

- (void)addDataPoint:(NSPoint)inPoint toLineIndex:(NSUInteger)inLineIndex
{
    id		dataObj;

    dataObj = myPrivateData->lineData[inLineIndex];
    if ( [ dataObj isKindOfClass:[ NSMutableArray class ] ] )
        [ (NSMutableArray *)dataObj addObject:NSStringFromPoint( inPoint ) ];
    else if ( [ dataObj isKindOfClass:[ NSMutableData class ] ] )
        [ (NSMutableData *)dataObj appendBytes:&inPoint length:sizeof(inPoint) ];
    else
    {
        NSLog( @"SM2DGraphView -addDataPoint:toLineIndex: can't add a point to line %ld", (long)inLineIndex );
        return;
    }
    [ self _sm_calculateGraphPaperRect ];
    if ( myPrivateData->flags.liveRefresh )
        [ self setNeedsDisplay:YES ];
}

- (NSImage *)imageOfView
{
    NSImage		*result = nil;

    result = [ [ [ NSImage alloc ] initWithSize: self.bounds .size ] autorelease ];

    // This provides a cached representation.
    [ result lockFocus ];

    // Fill with a white background.
    [ [ NSColor whiteColor ] set ];
    NSRectFill( self.bounds );

    // Draw the graph.
    [ self drawRect: self.bounds ];

    [ result unlockFocus ];

    return result;
}

- (NSRect)graphPaperRect
{
	return myPrivateData->graphRect;
}

- (NSPoint)convertPoint:(NSPoint)inPoint fromView:(NSView *)inView toLineIndex:(NSUInteger)inLineIndex
{
    NSPoint		result = inPoint;
    CGFloat		minX = 0, xScale = (CGFloat)1.0;
    CGFloat		minY = 0, yScale = (CGFloat)1.0;

    // First, get the point into the coordinate system of this view.
    if ( inView != self )
        result = [ self convertPoint:result fromView:inView ];

    if ( myPrivateData->flags.dataSourceIsValid )
    {
        // Now, determine the scales of this line index.
        minX = [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:inLineIndex
                    forAxis:kSM2DGraph_Axis_X ];
        xScale = [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:inLineIndex
                    forAxis:kSM2DGraph_Axis_X ] - minX;
        //if ( 0 != xScale )
		if(CGFloatAbs(xScale) >= SM2D_EPSILON)
            xScale = ( myPrivateData->graphRect.size.width - (CGFloat)1.0 ) / xScale;

        minY = [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:inLineIndex
                    forAxis:kSM2DGraph_Axis_Y ];
        yScale = [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:inLineIndex
                    forAxis:kSM2DGraph_Axis_Y ] - minY;
        //if ( 0 != yScale )
		if(CGFloatAbs(yScale) >= SM2D_EPSILON)
            yScale = ( myPrivateData->graphRect.size.height - (CGFloat)2.0 ) / yScale;
    }

    // Scale the result into the graphRect correctly.
	
    //if ( 0 != xScale )
	if(CGFloatAbs(xScale) >= SM2D_EPSILON)
        result.x = ( result.x - (CGFloat)1.0 - myPrivateData->graphRect.origin.x ) / xScale + minX;
    //if ( 0 != yScale )
	if(CGFloatAbs(yScale) >= SM2D_EPSILON)
        result.y = ( result.y - (CGFloat)1.0 - myPrivateData->graphRect.origin.y ) / yScale + minY;

    return result;
}

#pragma mark -
#pragma mark • PRIVATE METHODS

- (void)_sm_frameDidChange:(NSNotification *)inNote
{
    [ self _sm_calculateGraphPaperRect ];
}

- (void)_sm_calculateGraphPaperRect
{
    NSString	*t_string = nil, *lowerString = nil;
    NSRect		bounds = self.bounds , graphPaperRect;
    NSRect		tempRect = NSZeroRect;
    NSInteger	i;
    CGFloat		tempDouble;

    graphPaperRect = bounds;

	// Make room for overall title.
	if ( nil != myPrivateData->title && ((NSString *)myPrivateData->title).length != 0 )
	{
		if ( [ myPrivateData->title isKindOfClass:[ NSAttributedString class ] ] )
			tempRect.size = [ (NSAttributedString *)myPrivateData->title size ];
		else
			tempRect.size = [ (NSString *)myPrivateData->title
						sizeWithAttributes:myPrivateData->textAttributes ];
		if ( graphPaperRect.size.height > tempRect.size.height )
			graphPaperRect.size.height -= tempRect.size.height;

		tempRect = NSZeroRect;
	}

    for ( i = 0; i < [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_Y ]; i++ )
    {
        // Find the y axis labels, so we can get the max width and size the graph paper accordingly.
        // Figure out the default label.
        if ( myPrivateData->flags.dataSourceIsValid )
        {
            tempDouble = ( [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:0
                        forAxis:kSM2DGraph_Axis_Y ] - [ [ self dataSource ] twoDGraphView:self
                        minimumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_Y ] ) * (CGFloat)i /
                        (CGFloat)( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_Y ] - 1 );
            tempDouble += [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:0
                        forAxis:kSM2DGraph_Axis_Y ];
        }
        else
            tempDouble = i;

        // This is the default label.
        t_string = [ NSString stringWithFormat:@"%lg", (double)tempDouble ];

        if ( myPrivateData->flags.delegateLabelsTickMarks )
            t_string = [ [ self delegate ] twoDGraphView:self labelForTickMarkIndex:i forAxis:kSM2DGraph_Axis_Y
                        defaultLabel:t_string ];

		if ( 0 == i )
			lowerString = t_string;

        if ( nil != t_string )
        {
            tempRect.size = [ t_string sizeWithAttributes:myPrivateData->textAttributes ];
            if ( graphPaperRect.origin.x - bounds.origin.x < tempRect.size.width )
                graphPaperRect.origin.x = bounds.origin.x + tempRect.size.width;
        }
    }

    if ( graphPaperRect.origin.x > bounds.origin.x )
    {
        // Give a couple pixels spacing between labels and graph.
        graphPaperRect.origin.x += kSM2DGraph_LabelSpacing;
        graphPaperRect.size.width -= graphPaperRect.origin.x - bounds.origin.x;

        // Leave room at the top for half of the Y axis tick mark label that goes above the graph.
		if ( nil != t_string )	// This is the topmost Y axis tick mark string.
		{
			if ( [ self axisInsetForAxis:kSM2DGraph_Axis_Y ] < 1.0 )
				graphPaperRect.size.height -= ( tempRect.size.height / 2 ) + 1;
			else
			{
				if ( [ self axisInsetForAxis:kSM2DGraph_Axis_Y ] < ( tempRect.size.height / 2 ) + 1 )
					graphPaperRect.size.height -= ( tempRect.size.height / 2 ) + 1 - [ self
								axisInsetForAxis:kSM2DGraph_Axis_Y ];
			}
		}

        if ( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_X ] == 0 && nil != lowerString )
        {
            // Leave room at the bottom for half of the Y axis tick mark label that goes below the graph.
            if ( [ self axisInsetForAxis:kSM2DGraph_Axis_Y ] < 1.0 )
            {
                graphPaperRect.origin.y += ( tempRect.size.height / 2 ) + 1;
                graphPaperRect.size.height -= ( tempRect.size.height / 2 ) + 1;
            }
            else
            {
                if ( [ self axisInsetForAxis:kSM2DGraph_Axis_Y ] < ( tempRect.size.height / 2 ) + 1 )
                {
                    graphPaperRect.origin.y += ( tempRect.size.height / 2 ) + 1 - [ self
                                axisInsetForAxis:kSM2DGraph_Axis_Y ];
                    graphPaperRect.size.height -= ( tempRect.size.height / 2 ) + 1 - [ self
                                axisInsetForAxis:kSM2DGraph_Axis_Y ];
                }
            }
        }
    }

	lowerString = nil;
    for ( i = 0; i < [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_Y_Right ]; i++ )
    {
        // Find the y right axis labels, so we can get the max width and size the graph paper accordingly.
        // Figure out the default label.
        if ( myPrivateData->flags.dataSourceIsValid )
        {
            tempDouble = ( [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:0
                        forAxis:kSM2DGraph_Axis_Y_Right ] - [ [ self dataSource ] twoDGraphView:self
                        minimumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_Y_Right ] ) * (CGFloat)i /
                        (CGFloat)( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_Y_Right ] - 1 );
            tempDouble += [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:0
                        forAxis:kSM2DGraph_Axis_Y_Right ];
        }
        else
            tempDouble = i;

        // This is the default label.
        t_string = [ NSString stringWithFormat:@"%lg", (double)tempDouble ];

        if ( myPrivateData->flags.delegateLabelsTickMarks )
            t_string = [ [ self delegate ] twoDGraphView:self labelForTickMarkIndex:i
						forAxis:kSM2DGraph_Axis_Y_Right defaultLabel:t_string ];

		if ( 0 == i )
			lowerString = t_string;

        if ( nil != t_string )
        {
            tempRect.size = [ t_string sizeWithAttributes:myPrivateData->textAttributes ];
            if ( bounds.size.width - ( graphPaperRect.origin.x + graphPaperRect.size.width ) < tempRect.size.width )
                graphPaperRect.size.width = bounds.size.width - graphPaperRect.origin.x - tempRect.size.width;
        }
    }

    if ( (NSUInteger)(graphPaperRect.origin.x + graphPaperRect.size.width) != (NSUInteger)bounds.size.width )
    {
        // Give a couple pixels spacing between labels and graph.
        graphPaperRect.size.width -= kSM2DGraph_LabelSpacing;

		// if ( CGFloatAbs(graphPaperRect.origin.x == bounds.origin.x )
        if ( CGFloatAbs(graphPaperRect.origin.x - bounds.origin.x) < SM2D_EPSILON )
        {
            // Only have to do this part if it was not done above.
            // Leave room at the top for half of the y axis label that goes above the graph.
			if ( nil != t_string )
			{
				if ( [ self axisInsetForAxis:kSM2DGraph_Axis_Y ] < 1.0 )
					graphPaperRect.size.height -= ( tempRect.size.height / 2 ) + 1;
				else
				{
					if ( [ self axisInsetForAxis:kSM2DGraph_Axis_Y ] < ( tempRect.size.height / 2 ) + 1 )
						graphPaperRect.size.height -= ( tempRect.size.height / 2 ) + 1 - [ self
									axisInsetForAxis:kSM2DGraph_Axis_Y ];
				}
			}

            if ( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_X ] == 0 && nil != lowerString )
            {
                // Leave room at the bottom for half of the y axis label that goes below the graph.
                if ( [ self axisInsetForAxis:kSM2DGraph_Axis_Y ] < 1.0 )
                {
                    graphPaperRect.origin.y += ( tempRect.size.height / 2 ) + 1;
                    graphPaperRect.size.height -= ( tempRect.size.height / 2 ) + 1;
                }
                else
                {
                    if ( [ self axisInsetForAxis:kSM2DGraph_Axis_Y ] < ( tempRect.size.height / 2 ) + 1 )
                    {
                        graphPaperRect.origin.y += ( tempRect.size.height / 2 ) + 1 - [ self
                                    axisInsetForAxis:kSM2DGraph_Axis_Y ];
                        graphPaperRect.size.height -= ( tempRect.size.height / 2 ) + 1 - [ self
                                    axisInsetForAxis:kSM2DGraph_Axis_Y ];
                    }
                }
            }
        }
    }

    if ( nil != [ self labelForAxis:kSM2DGraph_Axis_X ] )
    {
        // Leave room for the X Axis label.
        tempRect.size = [ @"Any" sizeWithAttributes:myPrivateData->textAttributes ];
        graphPaperRect.origin.y += tempRect.size.height + kSM2DGraph_LabelSpacing;
        graphPaperRect.size.height -= tempRect.size.height + kSM2DGraph_LabelSpacing;
    }

    if ( 0 != [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_X ] )
    {
        // Leave room for the X axis tick mark labels.
        tempRect.size = [ @"Any" sizeWithAttributes:myPrivateData->textAttributes ];
        graphPaperRect.origin.y += tempRect.size.height + kSM2DGraph_LabelSpacing;
        graphPaperRect.size.height -= tempRect.size.height + kSM2DGraph_LabelSpacing;

        // Leave room at the left for half of the first X axis label that goes past the left edge of the graph.
        i = 0;
        if ( myPrivateData->flags.dataSourceIsValid )
        {
            tempDouble = ( [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:0
                        forAxis:kSM2DGraph_Axis_X ] - [ [ self dataSource ] twoDGraphView:self
                        minimumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_X ] ) *
                        (CGFloat)i / (CGFloat)( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_X ] - 1 );
            tempDouble += [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:0
                        forAxis:kSM2DGraph_Axis_X ];
        }
        else
            tempDouble = i;

        t_string = [ NSString stringWithFormat:@"%lg", (double)tempDouble ];

        if ( myPrivateData->flags.delegateLabelsTickMarks )
            t_string = [ [ self delegate ] twoDGraphView:self labelForTickMarkIndex:i forAxis:kSM2DGraph_Axis_X
                        defaultLabel:t_string ];
        if ( nil != t_string )
            tempRect.size = [ t_string sizeWithAttributes:myPrivateData->textAttributes ];
        else
            tempRect.size.width = 0;

        if ( [ self axisInsetForAxis:kSM2DGraph_Axis_X ] < 1.0 )
        {
            // No inset, so have to make room for half the width of the string off the edge.
            if ( graphPaperRect.origin.x - bounds.origin.x < ( tempRect.size.width / 2 ) + 1 )
            {
                tempDouble = bounds.origin.x + ( tempRect.size.width / 2 ) + 1 - graphPaperRect.origin.x;
                // Need to adjust the origin to the right by this amount (but keep right edge at same point)
                graphPaperRect.origin.x += tempDouble;
                graphPaperRect.size.width -= tempDouble;
            }
        }
        else if ( graphPaperRect.origin.x - bounds.origin.x + [ self axisInsetForAxis:kSM2DGraph_Axis_X ] <
                    ( tempRect.size.width / 2 ) + 1 )
        {
            // Not enough inset, so make room for half the width of the string (minus the inset) off the edge.
            tempDouble = bounds.origin.x + ( tempRect.size.width / 2 ) + 1 - [ self
                        axisInsetForAxis:kSM2DGraph_Axis_X ] - graphPaperRect.origin.x;
            graphPaperRect.origin.x += tempDouble;
            graphPaperRect.size.width -= tempDouble;
        }

        // Leave room at the right for half of the last X axis label that goes past the right edge of the graph.
        i = [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_X ] - 1;
        if ( myPrivateData->flags.dataSourceIsValid )
        {
            tempDouble = ( [ [ self dataSource ] twoDGraphView:self maximumValueForLineIndex:0
                        forAxis:kSM2DGraph_Axis_X ] - [ [ self dataSource ] twoDGraphView:self
                        minimumValueForLineIndex:0 forAxis:kSM2DGraph_Axis_X ] ) *
                        (CGFloat)i / (CGFloat)( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_X ] - 1 );
            tempDouble += [ [ self dataSource ] twoDGraphView:self minimumValueForLineIndex:0
                        forAxis:kSM2DGraph_Axis_X ];
        }
        else
            tempDouble = i;

        t_string = [ NSString stringWithFormat:@"%lg", (double)tempDouble ];

        if ( myPrivateData->flags.delegateLabelsTickMarks )
            t_string = [ [ self delegate ] twoDGraphView:self labelForTickMarkIndex:i forAxis:kSM2DGraph_Axis_X
                        defaultLabel:t_string ];
        if ( nil != t_string )
            tempRect.size = [ t_string sizeWithAttributes:myPrivateData->textAttributes ];
        else
            tempRect.size.width = 0;

        if ( [ self axisInsetForAxis:kSM2DGraph_Axis_X ] < 1.0 )
        {
            // No inset, so have to make room for half the width of the string off the edge.
            if ( bounds.size.width - ( graphPaperRect.origin.x + graphPaperRect.size.width ) <
                        ( tempRect.size.width / 2 ) + 1 )
            {
                graphPaperRect.size.width = bounds.size.width - graphPaperRect.origin.x -
                            ( tempRect.size.width / 2 ) - 1;
            }
        }
        else if ( [ self axisInsetForAxis:kSM2DGraph_Axis_X ] < ( tempRect.size.width / 2 ) + 1 )
        {
            // Not enough inset so make room for half the width of the string (minus the inset) off the edge.
            if ( bounds.size.width - ( graphPaperRect.origin.x + graphPaperRect.size.width ) <
                        ( tempRect.size.width / 2 ) + 1 - [ self axisInsetForAxis:kSM2DGraph_Axis_X ] )
            {
                graphPaperRect.size.width = bounds.size.width - graphPaperRect.origin.x -
                            ( tempRect.size.width / 2 ) - 1 + [ self axisInsetForAxis:kSM2DGraph_Axis_X ];
            }

        }
    }

    if ( nil != [ self labelForAxis:kSM2DGraph_Axis_Y ] )
    {
        // Leave room for the Y Axis label.
        tempRect.size = [ @"Any" sizeWithAttributes:myPrivateData->textAttributes ];
        graphPaperRect.origin.x += tempRect.size.height + kSM2DGraph_LabelSpacing;
        graphPaperRect.size.width -= tempRect.size.height + kSM2DGraph_LabelSpacing;
    }

    if ( nil != [ self labelForAxis:kSM2DGraph_Axis_Y_Right ] )
    {
        // Leave room for the Y Axis right side label.
        tempRect.size = [ @"Any" sizeWithAttributes:myPrivateData->textAttributes ];
        graphPaperRect.size.width -= tempRect.size.height + kSM2DGraph_LabelSpacing;
    }

	// Make sure we get an integral number of pixels (in screen coordinates for resolution independence).
	graphPaperRect = [ self convertRect:graphPaperRect toView:nil ];
	graphPaperRect = NSIntegralRect( graphPaperRect );
	graphPaperRect = [ self convertRect:graphPaperRect fromView:nil ];
	// Make sure we're right on a pixel, but not outside the bounds of the view.
	graphPaperRect = NSIntersectionRect( graphPaperRect, bounds );
	if ( graphPaperRect.size.height < (CGFloat)1.0 )
		graphPaperRect.size.height = (CGFloat)1.0;
	if ( graphPaperRect.size.width < (CGFloat)1.0 )
		graphPaperRect.size.width = (CGFloat)1.0;
    myPrivateData->graphPaperRect = graphPaperRect;

    // Now that we know how big the graphPaper will be, how big is the graph itself?
    if ( [ self axisInsetForAxis:kSM2DGraph_Axis_Y ] >= (CGFloat)1.0 || [ self axisInsetForAxis:kSM2DGraph_Axis_X ] >= (CGFloat)1.0 )
	{
        myPrivateData->graphRect = NSInsetRect( graphPaperRect, [ self axisInsetForAxis:kSM2DGraph_Axis_X ],
					[ self axisInsetForAxis:kSM2DGraph_Axis_Y ] );

		if ( myPrivateData->graphRect.size.height < (CGFloat)1.0 )
			myPrivateData->graphRect.size.height = (CGFloat)1.0;
		if ( myPrivateData->graphRect.size.width < (CGFloat)1.0 )
			myPrivateData->graphRect.size.width = (CGFloat)1.0;
	}
    else
        myPrivateData->graphRect = graphPaperRect;
}

- (void)_sm_drawGridInRect:(NSRect)inRect
{
    int				index1, index2;
    NSPoint			fromPoint, toPoint, dataPoint;
    CGFloat			xScale = (CGFloat)1.0, yScale = (CGFloat)1.0;
    NSRect			graphRect, graphPaperRect;

    graphPaperRect = myPrivateData->graphPaperRect;
    graphRect = myPrivateData->graphRect;

    // Draw the grid (default is blue at half transparency).
    [ [ self gridColor ] set ];

    if ( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_X ] > 1 )
    {
        // Draw the vertical grid lines.
        dataPoint.x = graphRect.size.width / ( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_X ] - 1 );
        xScale = dataPoint.x / (CGFloat)( [ self numberOfMinorTickMarksForAxis:kSM2DGraph_Axis_X ] + 1 );

        fromPoint.y = graphPaperRect.origin.y;
        toPoint.y = graphPaperRect.origin.y + graphPaperRect.size.height;
        if ( [ self borderColor ] != nil )
        {
            // Don't draw on top of the border.
            fromPoint.y++;
            toPoint.y--;
        }

        fromPoint.x = toPoint.x = graphRect.origin.x;
        if ( graphPaperRect.size.width > graphRect.size.width )
        {
            // Draw that first major line.
            [ NSBezierPath setDefaultLineWidth:1 ];
            [ NSBezierPath strokeLineFromPoint:fromPoint toPoint:toPoint ];
        }
        [ NSBezierPath setDefaultLineWidth:(CGFloat)0.5 ];
        for ( index2 = 0; index2 < [ self numberOfMinorTickMarksForAxis:kSM2DGraph_Axis_X ]; index2++ )
        {
            fromPoint.x = toPoint.x += xScale;
            [ NSBezierPath strokeLineFromPoint:fromPoint toPoint:toPoint ];
        }
        for ( index1 = 1; index1 < ( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_X ] - 1 ); index1++ )
        {
            [ NSBezierPath setDefaultLineWidth:1 ];
            toPoint.x = fromPoint.x = graphRect.origin.x + ( index1 * dataPoint.x );
            [ NSBezierPath strokeLineFromPoint:fromPoint toPoint:toPoint ];
            [ NSBezierPath setDefaultLineWidth:(CGFloat)0.5 ];
            for ( index2 = 0; index2 < [ self numberOfMinorTickMarksForAxis:kSM2DGraph_Axis_X ]; index2++ )
            {
                fromPoint.x = toPoint.x += xScale;
                [ NSBezierPath strokeLineFromPoint:fromPoint toPoint:toPoint ];
            }
        }

        if ( graphPaperRect.size.width > graphRect.size.width )
        {
            // Draw that last major line.
            [ NSBezierPath setDefaultLineWidth:1 ];
            toPoint.x = fromPoint.x = graphRect.origin.x + graphRect.size.width;
            [ NSBezierPath strokeLineFromPoint:fromPoint toPoint:toPoint ];
        }
    }

    if ( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_Y ] > 1 )
    {
        dataPoint.y = graphRect.size.height / ( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_Y ] - 1 );
        yScale = dataPoint.y / (CGFloat)( [ self numberOfMinorTickMarksForAxis:kSM2DGraph_Axis_Y ] + 1 );

        fromPoint.x = graphPaperRect.origin.x;
        toPoint.x = graphPaperRect.origin.x + graphPaperRect.size.width;
        if ( [ self borderColor ] != nil )
        {
            // Don't draw on top of the border.
            fromPoint.x++;
            toPoint.x--;
        }

        fromPoint.y = toPoint.y = graphRect.origin.y;
        if ( graphPaperRect.size.height > graphRect.size.height )
        {
            // Draw that first major line.
            [ NSBezierPath setDefaultLineWidth:1 ];
            [ NSBezierPath strokeLineFromPoint:fromPoint toPoint:toPoint ];
        }
        [ NSBezierPath setDefaultLineWidth:(CGFloat)0.5 ];
        for ( index2 = 0; index2 < [ self numberOfMinorTickMarksForAxis:kSM2DGraph_Axis_Y ]; index2++ )
        {
            fromPoint.y = toPoint.y += yScale;
            [ NSBezierPath strokeLineFromPoint:fromPoint toPoint:toPoint ];
        }
        for ( index1 = 1; index1 < ( [ self numberOfTickMarksForAxis:kSM2DGraph_Axis_Y ] - 1 ); index1++ )
        {
            [ NSBezierPath setDefaultLineWidth:1 ];
            toPoint.y = fromPoint.y = graphRect.origin.y + ( index1 * dataPoint.y );
            [ NSBezierPath strokeLineFromPoint:fromPoint toPoint:toPoint ];
            [ NSBezierPath setDefaultLineWidth:(CGFloat)0.5 ];
            for ( index2 = 0; index2 < [ self numberOfMinorTickMarksForAxis:kSM2DGraph_Axis_Y ]; index2++ )
            {
                fromPoint.y = toPoint.y += yScale;
                [ NSBezierPath strokeLineFromPoint:fromPoint toPoint:toPoint ];
            }
        }
        if ( graphPaperRect.size.height > graphRect.size.height )
        {
            // Draw that last major line.
            [ NSBezierPath setDefaultLineWidth:1 ];
            toPoint.y = fromPoint.y = graphRect.origin.y + graphRect.size.height;
            [ NSBezierPath strokeLineFromPoint:fromPoint toPoint:toPoint ];
        }
    }

    [ NSBezierPath setDefaultLineWidth:1 ];
}

#if SM2D_USE_CORE_GRAPHICS
- (void)_sm_drawSymbol:(SM2DGraphSymbolTypeEnum)inSymbol onLine:(NSPoint *)inLine count:(NSInteger)inPointCount
            inColor:(NSColor *)inColor inRect:(NSRect)inRect
#else
- (void)_sm_drawSymbol:(SM2DGraphSymbolTypeEnum)inSymbol onLine:(NSBezierPath *)inLine inColor:(NSColor *)inColor
            inRect:(NSRect)inRect
#endif
{
    NSMutableDictionary	*coloredAttributes;
    NSString			*t_string;
    NSInteger			pointIndex;
    NSPoint				offset;
#if !SM2D_USE_CORE_GRAPHICS
    NSBezierPathElement	element;
    NSPoint				pointArray[ 3 ];
    NSInteger			pointCount;
#endif
    NSRect				drawRect;

    // Make sure it draws in the correct color.
    if ( nil != inColor )
    {
        coloredAttributes = [ [ myPrivateData->textAttributes mutableCopy ]
                    autorelease ];
        coloredAttributes[NSForegroundColorAttributeName] = inColor;
    }
    else
        coloredAttributes = myPrivateData->textAttributes;

    // Get the symbol (as text) and it's size.
    t_string = _sm_local_getSymbolForEnum( inSymbol );
    drawRect.size = [ t_string sizeWithAttributes:coloredAttributes ];
    offset.x = drawRect.size.width / 2;
    offset.y = drawRect.size.height / 2;

#if SM2D_USE_CORE_GRAPHICS
    for ( pointIndex = 0; pointIndex < inPointCount; pointIndex++ )
    {
        drawRect.origin.x = inLine[ pointIndex ].x - offset.x;
        drawRect.origin.y = inLine[ pointIndex ].y - offset.y;

        if ( NSIntersectsRect( inRect, drawRect ) )
            [ t_string drawInRect:drawRect withAttributes:coloredAttributes ];
    } // for all elements in inLine
#else
    pointCount = inLine.elementCount ;
    for ( pointIndex = 0; pointIndex < pointCount; pointIndex++ )
    {
        element = [ inLine elementAtIndex:pointIndex associatedPoints:pointArray ];
        if ( element == NSMoveToBezierPathElement || element == NSLineToBezierPathElement )
        {
            drawRect.origin.x = pointArray[ 0 ].x - offset.x;
            drawRect.origin.y = pointArray[ 0 ].y - offset.y;

            if ( NSIntersectsRect( inRect, drawRect ) )
                [ t_string drawInRect:drawRect withAttributes:coloredAttributes ];
        }
    } // for all elements in inLine
#endif
}

- (void)_sm_drawVertBarFromPoint:(NSPoint)inFromPoint toPoint:(NSPoint)inToPoint barNumber:(NSInteger)inBarNumber
            of:(NSInteger)inBarCount inColor:(NSColor *)inColor
{
	NSBezierPath		*t_path;
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_2
	NSGraphicsContext	*context;
	CTGradient			*gradient;
#endif
	NSRect				t_draw_rect;

    t_draw_rect.size.width = [ SM2DGraphView barWidth ];
    t_draw_rect.origin.x = inFromPoint.x - ( t_draw_rect.size.width / (CGFloat)2.0 );
    // Now offset the origin by the bar index.
    if ( inBarCount > 1 )
    {
        if ( inBarNumber < ( (CGFloat)inBarCount / (CGFloat)2.0 ) )
            t_draw_rect.origin.x -= ( ( inBarCount / 2 ) - inBarNumber ) * t_draw_rect.size.width;
        else
            t_draw_rect.origin.x += ( inBarNumber - ( inBarCount / 2 ) ) * t_draw_rect.size.width;
        if ( ( inBarCount % 2 ) == 0 )
            t_draw_rect.origin.x -= t_draw_rect.size.width / (CGFloat)2.0;
    }

	if ( inToPoint.y < inFromPoint.y )
	{
		// Going below the zero point.
		t_draw_rect.size.height = CGFloatFloor( inFromPoint.y - inToPoint.y + (CGFloat)0.5 );
		t_draw_rect.origin.y = inToPoint.y;
	}
	else
	{
		// Going above the zero point.
		t_draw_rect.origin.y = CGFloatFloor( inFromPoint.y + (CGFloat)0.5 );
		t_draw_rect.size.height = inToPoint.y - t_draw_rect.origin.y;	// No need to make this an integer!
	}

	// Create a rounded path to fill in for the bar.
	t_path = _sm_local_bar_bezier_path( t_draw_rect, ( inToPoint.y < inFromPoint.y ) ? 1 : 2, (CGFloat)5.0 );

	[ inColor set ];
	[ t_path fill ];

#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_2

	// Now to do some highlights with CTGradient (requires 10.2 as a minimum version)

	if ( inToPoint.y < inFromPoint.y )
	{	// Going below the zero point.
		if ( t_draw_rect.size.height > (CGFloat)0.5 )
		{
			t_draw_rect.size.height -= (CGFloat)0.5;
			t_draw_rect.origin.y += (CGFloat)0.5;
		}
		else
			t_draw_rect.size.height = (CGFloat)0.0;
	}
	else
	{	// Going above the zero point.
		if ( t_draw_rect.size.height > (CGFloat)0.5 )
			t_draw_rect.size.height -= (CGFloat)0.5;
		else
			t_draw_rect.size.height = (CGFloat)0.0;
	}

	t_path = _sm_local_bar_bezier_path( t_draw_rect, ( inToPoint.y < inFromPoint.y ) ? 1 : 2, (CGFloat)6.5 );

	context = [ NSGraphicsContext currentContext ];
	[ context saveGraphicsState ];

	[ t_path addClip ];

	// Create a gradient that more or less mimics Apple's scroller gradient.
	gradient = [ CTGradient gradientWithBeginningColor:inColor endingColor:inColor ];
	gradient = [ gradient addColorStop:[ inColor blendedColorWithFraction:(CGFloat)0.6 ofColor:[ NSColor whiteColor ] ]
				atPosition:(CGFloat)0.2 ];
	gradient = [ gradient addColorStop:[ inColor blendedColorWithFraction:(CGFloat)0.5 ofColor:[ NSColor whiteColor ] ]
				atPosition:(CGFloat)0.35 ];
	gradient = [ gradient addColorStop:[ inColor blendedColorWithFraction:(CGFloat)0.3 ofColor:[ NSColor whiteColor ] ]
				atPosition:(CGFloat)0.4 ];
	gradient = [ gradient addColorStop:[ inColor blendedColorWithFraction:(CGFloat)0.8 ofColor:[ NSColor whiteColor ] ]
				atPosition:(CGFloat)0.9 ];
	[ gradient fillRect:t_draw_rect angle:(CGFloat)0.0 ];

	[ context restoreGraphicsState ];

#endif // highlights with CTGradient
}

#pragma mark -
#pragma mark • LOCAL FUNCTIONS

static SM2DGraphAxisRecord *_sm_local_determineAxis( SM2DGraphAxisEnum inAxis, SM2DPrivateData *inPrivateData )
{
    SM2DGraphAxisRecord *result = nil;

    if ( inAxis == kSM2DGraph_Axis_X )
        result = &inPrivateData->xAxisInfo;
    else if ( inAxis == kSM2DGraph_Axis_Y_Right )
        result = &inPrivateData->yRightAxisInfo;
    else
        result = &inPrivateData->yAxisInfo;

    return result;
}

#define kUnicode_WhiteUpTriangle	0x25B3
#define kUnicode_BlackUpTriangle	0x25B2
#define kUnicode_WhiteDownTriangle	0x25BD
#define kUnicode_BlackDownTriangle	0x25BC
#define kUnicode_WhiteCircle		0x25CB
#define kUnicode_BlackCircle		0x25CF
#define kUnicode_WhiteDiamond		0x25C7
#define kUnicode_BlackDiamond		0x25C6
#define kUnicode_WhiteSquare		0x25A1
#define kUnicode_BlackSquare		0x25A0
#define kUnicode_WhiteStar			0x2606
#define kUnicode_BlackStar			0x2605

static NSString *_sm_local_getSymbolForEnum( SM2DGraphSymbolTypeEnum inValue )
{
    NSString	*result = nil;

    switch ( inValue )
    {
    default:
    case kSM2DGraph_Symbol_None:
        // Nothing.
        break;
    case kSM2DGraph_Symbol_Triangle:
		result = [ NSString stringWithFormat:@"%C", kUnicode_WhiteUpTriangle ];
        break;
    case kSM2DGraph_Symbol_Diamond:
		result = [ NSString stringWithFormat:@"%C", kUnicode_WhiteDiamond ];
        break;
    case kSM2DGraph_Symbol_Circle:
		result = [ NSString stringWithFormat:@"%C", kUnicode_WhiteCircle ];
        break;
    case kSM2DGraph_Symbol_X:
        result = @"x";
        break;
    case kSM2DGraph_Symbol_Plus:
        result = @"+";
        break;
    case kSM2DGraph_Symbol_FilledCircle:
		result = [ NSString stringWithFormat:@"%C", kUnicode_BlackCircle ];
        break;
    case kSM2DGraph_Symbol_Square:
		result = [ NSString stringWithFormat:@"%C", kUnicode_WhiteSquare ];
        break;
    case kSM2DGraph_Symbol_Star:
		result = [ NSString stringWithFormat:@"%C", kUnicode_WhiteStar ];
        break;
    case kSM2DGraph_Symbol_InvertedTriangle:
		result = [ NSString stringWithFormat:@"%C", kUnicode_WhiteDownTriangle ];
        break;
    case kSM2DGraph_Symbol_FilledSquare:
		result = [ NSString stringWithFormat:@"%C", kUnicode_BlackSquare ];
        break;
    case kSM2DGraph_Symbol_FilledTriangle:
		result = [ NSString stringWithFormat:@"%C", kUnicode_BlackUpTriangle ];
        break;
    case kSM2DGraph_Symbol_FilledDiamond:
		result = [ NSString stringWithFormat:@"%C", kUnicode_BlackDiamond ];
        break;
    case kSM2DGraph_Symbol_FilledInvertedTriangle:
		result = [ NSString stringWithFormat:@"%C", kUnicode_BlackDownTriangle ];
        break;
	case kSM2DGraph_Symbol_FilledStar:
		result = [ NSString stringWithFormat:@"%C", kUnicode_BlackStar ];
		break;
    }

    return result;
}

static NSDictionary *_sm_local_defaultLineAttributes( NSUInteger inLineIndex )
{
    NSColor		*tempColor;

    switch ( inLineIndex % 7 )
    {
    default:
    case 0:		tempColor = [ NSColor blackColor ];		break;
    case 1:		tempColor = [ NSColor redColor ];		break;
    case 2:		tempColor = [ NSColor greenColor ];		break;
    case 3:		tempColor = [ NSColor blueColor ];		break;
    case 4:		tempColor = [ NSColor yellowColor ];	break;
    case 5:		tempColor = [ NSColor cyanColor ];		break;
    case 6:		tempColor = [ NSColor magentaColor ];	break;
    }

    return @{NSForegroundColorAttributeName: tempColor};
}

static NSString *kSM2DGraph_Key_Label = @"Label";
static NSString *kSM2DGraph_Key_ScaleType = @"Scale";
static NSString *kSM2DGraph_Key_NumberOfTicks = @"Ticks";
static NSString *kSM2DGraph_Key_NumberOfMinorTicks = @"MinorTicks";
static NSString *kSM2DGraph_Key_Inset = @"Inset";
static NSString *kSM2DGraph_Key_DrawLineAtZero = @"DrawLineAtZero";
static NSString *kSM2DGraph_Key_TickMarkPosition = @"TickMarkPosition";

static NSDictionary *_sm_local_encodeAxisInfo( SM2DGraphAxisRecord *inAxis )
{
    NSMutableDictionary	*result = [ NSMutableDictionary dictionaryWithCapacity:7 ];

    if ( nil != inAxis->label )
        if ( 0 != inAxis->label.length )
            result[kSM2DGraph_Key_Label] = inAxis->label;

    result[kSM2DGraph_Key_ScaleType] = [ NSNumber numberWithInt:inAxis->scaleType ];
    result[kSM2DGraph_Key_NumberOfTicks] = @(inAxis->numberOfTickMarks);
    result[kSM2DGraph_Key_NumberOfMinorTicks] = @(inAxis->numberOfMinorTickMarks);
    result[kSM2DGraph_Key_Inset] = @(inAxis->inset);
    result[kSM2DGraph_Key_DrawLineAtZero] = @(inAxis->drawLineAtZero);
    result[kSM2DGraph_Key_TickMarkPosition] = @(inAxis->tickMarkPosition);

    return [ [ result copy ] autorelease ];
}

static void _sm_local_decodeAxisInfo( NSDictionary *inInfo, SM2DGraphAxisRecord *outAxis ) 
{
    if ( nil != inInfo && nil != outAxis )
    {
        outAxis->label = [ inInfo[kSM2DGraph_Key_Label] retain ];
        outAxis->scaleType = [ inInfo[kSM2DGraph_Key_ScaleType] intValue ];
        outAxis->numberOfTickMarks = [ inInfo[kSM2DGraph_Key_NumberOfTicks] intValue ];
        outAxis->numberOfMinorTickMarks = [ inInfo[kSM2DGraph_Key_NumberOfMinorTicks] intValue ];
        outAxis->inset = [ inInfo[kSM2DGraph_Key_Inset] CGFloatValue ];
        outAxis->drawLineAtZero = [ inInfo[kSM2DGraph_Key_DrawLineAtZero] boolValue ];
        outAxis->tickMarkPosition = [ inInfo[kSM2DGraph_Key_TickMarkPosition] boolValue ];
    }
}

static NSBezierPath *_sm_local_bar_bezier_path( NSRect inRect, unsigned char inRoundedEdge, CGFloat inRadius )
{
	NSBezierPath	*result;
	CGFloat			max_x, mid_x;
	CGFloat			max_y, mid_y;

	max_x = NSMaxX( inRect );
	mid_x = NSMidX( inRect );

	max_y = NSMaxY( inRect );
	mid_y = NSMidY( inRect );

	result = [ NSBezierPath bezierPath ];
	if ( inRoundedEdge == 1 )
	{	// Round off the bottom corners.

		[ result moveToPoint:NSMakePoint( mid_x, max_y ) ];
		// Sharp upper-right corner.
		[ result lineToPoint:NSMakePoint( max_x, max_y ) ];
		[ result lineToPoint:NSMakePoint( max_x, mid_y ) ];
		// Arced bottom-right corner
		[ result appendBezierPathWithArcFromPoint:NSMakePoint( max_x, inRect.origin.y )
					toPoint:NSMakePoint( mid_x, inRect.origin.y ) radius:inRadius ];
		// Arced bottom-left corner
		[ result appendBezierPathWithArcFromPoint:NSMakePoint( inRect.origin.x, inRect.origin.y )
					toPoint:NSMakePoint( inRect.origin.x, mid_y ) radius:inRadius ];
		// Sharp upper-left corner.
		[ result lineToPoint:NSMakePoint( inRect.origin.x, max_y ) ];
	}
	else if ( inRoundedEdge == 2 )
	{	// Round off the top corners.
		[ result moveToPoint:NSMakePoint( mid_x, inRect.origin.y ) ];
		// Sharp lower-right corner.
		[ result lineToPoint:NSMakePoint( inRect.origin.x, inRect.origin.y ) ];
		[ result lineToPoint:NSMakePoint( inRect.origin.x, mid_y ) ];
		// Arced top-left corner
		[ result appendBezierPathWithArcFromPoint:NSMakePoint( inRect.origin.x, max_y )
					toPoint:NSMakePoint( mid_x, max_y ) radius:inRadius ];
		// Arced top-right corner
		[ result appendBezierPathWithArcFromPoint:NSMakePoint( max_x, max_y )
					toPoint:NSMakePoint( max_x, mid_y ) radius:inRadius ];
		// Sharp lower-right corner.
		[ result lineToPoint:NSMakePoint( max_x, inRect.origin.y ) ];
	}
	[ result closePath ];

	return result;
}

#pragma mark -
#pragma mark • ALTIVEC IMPLEMENTATION

#if __ppc__

static BOOL _sm_local_isAltiVecPresent( void )
{
    SInt32	cpuAttributes;
    BOOL	result = NO;
    OSErr	err;

	// First, check that we're greater than a G3 processor.
	// This is needed because some old processors return unreliable results from
	// the gestaltPowerPCProcessorFeatures check.
	err = Gestalt( gestaltNativeCPUtype, &cpuAttributes );
	if ( noErr == err && cpuAttributes > gestaltCPU750 )
	{
		// Now check to see if we have AltiVec.
		err = Gestalt( gestaltPowerPCProcessorFeatures, &cpuAttributes );
		if ( noErr == err )
			result = ( 0 != ( ( 1 << gestaltPowerPCHasVectorInstructions ) & cpuAttributes ) );
	}

    return result;
}

static vFloat vecFromFloats( CGFloat a, CGFloat b, CGFloat c, CGFloat d )
{
   vFloat	returnme;
   float	*returnme_ptr; 

   returnme_ptr = (float *)&returnme;

   returnme_ptr[ 0 ] = a;
   returnme_ptr[ 1 ] = b; 
   returnme_ptr[ 2 ] = c; 
   returnme_ptr[ 3 ] = d; 

   return returnme; 
}

static void _sm_local_scaleDataUsingVelocityEngine( NSPoint *ioPoints, unsigned long inDataCount,
                                CGFloat minX, CGFloat xScale, CGFloat xOrigin,
                                CGFloat minY, CGFloat yScale, CGFloat yOrigin )
{
    vFloat	*pointsPtr, *endPtr;

    // Set up the vectors for the minimum, scale, and origin.
    // Note: each NSPoint is an X and Y CGFloat.  There are two NSPoints within each vector.
    // The even indices of the 4 floats are the X coordinates and the odd indices are the Y coordinates.
    vFloat	minimumVec = vecFromFloats( minX, minY, minX, minY );
	vFloat	scaleVec = vecFromFloats( xScale, yScale, xScale, yScale );
	vFloat	originVec = vecFromFloats( xOrigin, yOrigin, xOrigin, yOrigin );

	// Point at the beginning of the data.
    pointsPtr = (vFloat *)ioPoints;
    // Velocity Engine does 4 floats at a time, and each NSPoint is 2 floats.
    // Thus we can go through two points per loop.
    endPtr = &pointsPtr[ inDataCount / 2 ];

    while ( pointsPtr != endPtr )
    {
        // First, subtract the minimum values.
        // Next, multiply by the scale and add the origin (ALL IN ONE INSTRUCTION!).
        // That's the finished point.
        *pointsPtr = vec_madd( vec_sub( *pointsPtr, minimumVec ), scaleVec, originVec );

        pointsPtr++;    // Work on the next set of four floats.
    }

    // We may have a number of points not divisible by 2.
    if ( 0 != ( inDataCount % 2 ) )
    {
        // Do the last point using the normal CPU.
        ioPoints[ inDataCount - 1 ].x = ( ioPoints[ inDataCount - 1 ].x - minX ) * xScale + xOrigin;
        ioPoints[ inDataCount - 1 ].y = ( ioPoints[ inDataCount - 1 ].y - minY ) * yScale + yOrigin;
    }
}

#endif // __ppc__

@end
