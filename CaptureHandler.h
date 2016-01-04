//
//  CaptureHandler.h
//  Eavesdrop
//
//  Created by Eric Baur on Mon Nov 15 2004.
//  Copyright (c) 2004 Eric Shore Baur. All rights reserved.
//

@protocol CaptureHandler
- (oneway void)setSaveFile:(NSString *)saveFile;
- (oneway void)setReadFile:(NSString *)readFile;
@property (NS_NONATOMIC_IOSONLY) BOOL capturesPayload;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL startCapture;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _startCapture;
- (oneway void)stopCapture;
- (oneway void)_stopCapture;
- (oneway void)captureThreadWithID:(NSString *)capID;
@property (NS_NONATOMIC_IOSONLY, getter=isActive, readonly) BOOL active;
//- (NSDictionary *)stats;

- (oneway void)setCaptureFilter:(NSString *)filterString;
- (oneway void)setDevice:(NSString *)newDevice;
- (void)setPromiscuous:(BOOL)promiscuousMode;
@end
