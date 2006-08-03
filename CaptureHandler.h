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
- (oneway void)setCapturesPayload:(BOOL)shouldCapture;
- (BOOL)capturesPayload;

- (BOOL)startCapture;
- (BOOL)_startCapture;
- (oneway void)stopCapture;
- (oneway void)_stopCapture;
- (oneway void)captureThreadWithID:(NSString *)capID;
- (BOOL)isActive;
//- (NSDictionary *)stats;

- (oneway void)setCaptureFilter:(NSString *)filterString;
- (oneway void)setDevice:(NSString *)newDevice;
- (void)setPromiscuous:(BOOL)promiscuousMode;
@end
