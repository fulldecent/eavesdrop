//
//  EavesdropAppDelegate.h
//  Eavesdrop
//
//  Created by Eric Baur on 5/16/06.
//  Copyright 2006 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CaptureHandlers.h"
#import "PluginsController.h"

@protocol ClientAppDelegate

- (oneway void)captureTaskStarted;
- (BOOL)isAppRunning;

@end

@interface EavesdropAppDelegate : NSObject <ClientAppDelegate> {
	IBOutlet NSWindow *preferencesWindow;
	IBOutlet PluginsController *pluginsController;
}

- (IBAction)launchCaptureServer:(id)sender;

- (IBAction)savePreferences:(id)sender;
- (IBAction)cancelPreferences:(id)sender;

@end
