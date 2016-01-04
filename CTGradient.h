//
//  CTGradient.h
//
//  Created by Chad Weider on 2/14/07.
//  Copyright (c) 2007 Chad Weider.
//  Some rights reserved: <http://creativecommons.org/licenses/by/2.5/>
//
//  Version: 1.6

#import <Cocoa/Cocoa.h>

// used to convert [(float)x == (float)y] -> [CGFloatAbs(x-y) < SM2D_EPSILON]
#define SM2D_EPSILON ((CGFloat)0.000000001)

#if defined(__LP64__)
#define CGFloatValue	doubleValue
#define setCGFloatValue	setDoubleValue
#define CGFloatRound(x) round(x)
#define CGFloatAbs(x)	fabs(x)
#define CGFloatCeil(x)	ceil(x)
#define CGFloatFloor(x)	floor(x)
#define CGFloatMod(x,y)	fmod(x,y)

#define CGFloatTan(x)	tan(x)
#define CGFloatSin(x)	sin(x)
#define CGFloatCos(x)	cos(x)
#else
#define CGFloatValue	floatValue
#define setCGFloatValue	setFloatValue
#define CGFloatRound(x) roundf(x)
#define CGFloatAbs(x)	fabsf(x)
#define CGFloatCeil(x)	ceilf(x)
#define CGFloatFloor(x)	floorf(x)

#define CGFloatTan(x)	tanf(x)
#define CGFloatSin(x)	sinf(x)
#define CGFloatCos(x)	cosf(x)
#define CGFloatMod(x,y)	fmodf(x,y)
#endif

#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_2

typedef struct _CTGradientElement 
	{
	CGFloat red, green, blue, alpha;
	CGFloat position;
	
	struct _CTGradientElement *nextElement;
	} CTGradientElement;

typedef enum  _CTBlendingMode
	{
	CTLinearBlendingMode,
	CTChromaticBlendingMode,
	CTInverseChromaticBlendingMode
	} CTGradientBlendingMode;


@interface CTGradient : NSObject <NSCopying, NSCoding>
	{
	CTGradientElement* elementList;
	CTGradientBlendingMode blendingMode;
	
	CGFunctionRef gradientFunction;
	}

+ (id)gradientWithBeginningColor:(NSColor *)begin endingColor:(NSColor *)end;

+ (id)aquaSelectedGradient;
+ (id)aquaNormalGradient;
+ (id)aquaPressedGradient;

+ (id)unifiedSelectedGradient;
+ (id)unifiedNormalGradient;
+ (id)unifiedPressedGradient;
+ (id)unifiedDarkGradient;

+ (id)sourceListSelectedGradient;
+ (id)sourceListUnselectedGradient;

+ (id)rainbowGradient;
+ (id)hydrogenSpectrumGradient;

- (CTGradient *)gradientWithAlphaComponent:(CGFloat)alpha;

- (CTGradient *)addColorStop:(NSColor *)color atPosition:(CGFloat)position;	//positions given relative to [0,1]
- (CTGradient *)removeColorStopAtIndex:(NSUInteger)index;
- (CTGradient *)removeColorStopAtPosition:(CGFloat)position;

- (CTGradientBlendingMode)blendingMode;
- (NSColor *)colorStopAtIndex:(NSUInteger)index;
- (NSColor *)colorAtPosition:(CGFloat)position;


- (void)drawSwatchInRect:(NSRect)rect;
- (void)fillRect:(NSRect)rect angle:(CGFloat)angle;					//fills rect with axial gradient
																	//	angle in degrees
- (void)radialFillRect:(NSRect)rect;								//fills rect with radial gradient
																	//  gradient from center outwards
- (void)fillBezierPath:(NSBezierPath *)path angle:(CGFloat)angle;
- (void)radialFillBezierPath:(NSBezierPath *)path;

@end

#endif // #if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_2
