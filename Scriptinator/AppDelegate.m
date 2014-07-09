//
//  AppDelegate.m
//  Scriptinator
//
//  Created by Craig Hockenberry on 6/21/14.
//  Copyright (c) 2014 Craig Hockenberry. All rights reserved.
//

#import "AppDelegate.h"

#import <Carbon/Carbon.h> // for AppleScript definitions

@interface AppDelegate ()

@property (nonatomic) IBOutlet NSTextField *chockifyInputTextField;
@property (nonatomic) IBOutlet NSTextField *chockifyOutputTextField;

@property (nonatomic) IBOutlet NSTextField *URLOutputTextField;
@property (nonatomic) IBOutlet NSTextField *URLInputTextField;
@property (nonatomic) IBOutlet NSTextView *HTMLTextView;

@property (nonatomic, strong) dispatch_semaphore_t appleScriptTaskSemaphore;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// this semaphore is used by -openNetworkPreferences to ensure synchronous execution of the script
	self.appleScriptTaskSemaphore = dispatch_semaphore_create(1);
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application
{
	return YES;
}


#pragma mark - Scripting

- (NSAppleEventDescriptor *)chockifyEventDescriptorWithString:(NSString *)inputString
{
	// parameter
	NSAppleEventDescriptor *parameter = [NSAppleEventDescriptor descriptorWithString:inputString];
	NSAppleEventDescriptor *parameters = [NSAppleEventDescriptor listDescriptor];
	[parameters insertDescriptor:parameter atIndex:1]; // you have to love a language with indices that start at 1 instead of 0
	
	// target
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	// function
	NSAppleEventDescriptor *function = [NSAppleEventDescriptor descriptorWithString:@"chockify"];
	
	// event
	NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:function forKeyword:keyASSubroutineName];
	[event setParamDescriptor:parameters forKeyword:keyDirectObject];
	
	return event;
}

- (NSAppleEventDescriptor *)safariURLEventDescriptor
{
	// target
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	// function
	NSAppleEventDescriptor *function = [NSAppleEventDescriptor descriptorWithString:@"safariURL"];
	
	// event
	NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:function forKeyword:keyASSubroutineName];
	
	return event;
}

- (NSAppleEventDescriptor *)setSafariURLEventDescriptorWithString:(NSString *)URLString
{
	// parameter
	NSAppleEventDescriptor *parameter = [NSAppleEventDescriptor descriptorWithString:URLString];
	NSAppleEventDescriptor *parameters = [NSAppleEventDescriptor listDescriptor];
	[parameters insertDescriptor:parameter atIndex:1];
	
	// target
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	// function
	NSAppleEventDescriptor *function = [NSAppleEventDescriptor descriptorWithString:@"setSafariURL"];
	
	// event
	NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:function forKeyword:keyASSubroutineName];
	[event setParamDescriptor:parameters forKeyword:keyDirectObject];
	
	return event;
}

- (NSAppleEventDescriptor *)safariHTMLEventDescriptor
{
	// target
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	// function
	NSAppleEventDescriptor *function = [NSAppleEventDescriptor descriptorWithString:@"safariHTML"];
	
	// event
	NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:function forKeyword:keyASSubroutineName];
	
	return event;
}

- (NSAppleEventDescriptor *)openNetworkPreferencesEventDescriptor
{
	// target
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	// function
	NSAppleEventDescriptor *function = [NSAppleEventDescriptor descriptorWithString:@"openNetworkPreferences"];
	
	// event
	NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:function forKeyword:keyASSubroutineName];
	
	return event;
}

#pragma mark -

- (NSString *)stringForResultEventDescriptor:(NSAppleEventDescriptor *)resultEventDescriptor
{
	NSString *result = nil;
	
	if (resultEventDescriptor) {
		if ([resultEventDescriptor descriptorType] != kAENullEvent) {
			if ([resultEventDescriptor descriptorType] == kTXNUnicodeTextData) {
				result = [resultEventDescriptor stringValue];
			}
		}
	}
	
	return result;
}

- (NSURL *)URLForResultEventDescriptor:(NSAppleEventDescriptor *)resultEventDescriptor
{
	NSURL *result = nil;
	
	NSString *URLString = nil;
	if (resultEventDescriptor) {
		if ([resultEventDescriptor descriptorType] != kAENullEvent) {
			if ([resultEventDescriptor descriptorType] == kTXNUnicodeTextData) {
				URLString = [resultEventDescriptor stringValue];
			}
		}
	}
	
	if (URLString && [URLString length] > 0) {
		result = [NSURL URLWithString:URLString];
	}
	
	return result;
}

#pragma mark - Utility

- (NSUserAppleScriptTask *)automationScriptTask
{
	NSUserAppleScriptTask *result = nil;
	
	NSError *error;
	NSURL *directoryURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
	if (directoryURL) {
		NSURL *scriptURL = [directoryURL URLByAppendingPathComponent:@"Automation.scpt"];
		result = [[NSUserAppleScriptTask alloc] initWithURL:scriptURL error:&error];
		if (! result) {
			NSLog(@"%s no AppleScript task error = %@", __PRETTY_FUNCTION__, error);
		}
	}
	else {
		// NOTE: if you're not running in a sandbox, the directory URL will always be nil
		NSLog(@"%s no Application Scripts folder error = %@", __PRETTY_FUNCTION__, error);
	}

	return result;
}

- (void)updateChockifyTextFieldWithString:(NSString *)string
{
	NSLog(@"%s string = %@", __PRETTY_FUNCTION__, string);
	[self.chockifyOutputTextField setStringValue:string];
}

- (void)updateURLTextFieldWithURL:(NSURL *)URL
{
	NSLog(@"%s URL = %@", __PRETTY_FUNCTION__, URL);
	[self.URLOutputTextField setStringValue:[URL absoluteString]];
}

- (void)updateHTMLTextFieldWithString:(NSString *)string
{
	NSLog(@"%s string = %@", __PRETTY_FUNCTION__, string);
	[self.HTMLTextView setString:string];
}

- (void)showNetworkAlert
{
	NSAlert *alert = [NSAlert alertWithMessageText:@"Network Preferences Open" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The Network preferences panel is now open."];
	[alert runModal];
}

#pragma mark - Actions

- (IBAction)CHOCKIFYDUH:(id)sender
{
	// run the script from the application's bundle
	
	NSURL *URL = [[NSBundle mainBundle] URLForResource:@"Automation" withExtension:@"scpt"];
	if (URL) {
		NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:URL error:NULL];
		
		NSAppleEventDescriptor *event = [self chockifyEventDescriptorWithString:[self.chockifyInputTextField stringValue]];
		NSDictionary *error = nil;
		NSAppleEventDescriptor *resultEventDescriptor = [appleScript executeAppleEvent:event error:&error];
		if (! resultEventDescriptor) {
			NSLog(@"%s AppleScript run error = %@", __PRETTY_FUNCTION__, error);
		}
		else {
			NSString *string = [self stringForResultEventDescriptor:resultEventDescriptor];
			[self updateChockifyTextFieldWithString:string];
		}
	}
}

- (IBAction)bummer:(id)sender
{
	// run the script from the application's bundle -- and fail
	
	NSURL *URL = [[NSBundle mainBundle] URLForResource:@"Automation" withExtension:@"scpt"];
	if (URL) {
		NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:URL error:NULL];
		
		NSAppleEventDescriptor *event = [self safariURLEventDescriptor];
		NSDictionary *error = nil;
		NSAppleEventDescriptor *resultEventDescriptor = [appleScript executeAppleEvent:event error:&error];
		if (! resultEventDescriptor) {
			NSLog(@"%s AppleScript run error = %@", __PRETTY_FUNCTION__, error);
			
			// AppleScript says that Safari isn't running, even when it is...
		}
		else {
			NSURL *URL = [self URLForResultEventDescriptor:resultEventDescriptor];
			[self updateURLTextFieldWithURL:URL];
		}
	}
}

- (IBAction)installAutomationScript:(id)sender
{
	// NOTE: For this to work, you MUST update the Capbilities > App Sandbox > File Access > User Selected File to Read/Write.
	
	NSError *error;
	NSURL *directoryURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setDirectoryURL:directoryURL];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setPrompt:@"Select Script Folder"];
	[openPanel setMessage:@"Please select the User > Library > Application Scripts > com.iconfactory.Scriptinator folder"];
	[openPanel beginWithCompletionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			NSURL *selectedURL = [openPanel URL];
			if ([selectedURL isEqual:directoryURL]) {
				NSURL *destinationURL = [selectedURL URLByAppendingPathComponent:@"Automation.scpt"];
				NSFileManager *fileManager = [NSFileManager defaultManager];
				NSURL *sourceURL = [[NSBundle mainBundle] URLForResource:@"Automation" withExtension:@"scpt"];
				NSError *error;
				BOOL success = [fileManager copyItemAtURL:sourceURL toURL:destinationURL error:&error];
				if (success) {
					NSAlert *alert = [NSAlert alertWithMessageText:@"Script Installed" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The Automation script was installed succcessfully."];
					[alert runModal];
					
					// NOTE: This is a bit of a hack to get the Application Scripts path out of the next open or save panel that appears.
					[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"NSNavLastRootDirectory"];
				}
				else {
					NSLog(@"%s error = %@", __PRETTY_FUNCTION__, error);
					if ([error code] == NSFileWriteFileExistsError) {
						// the script was already installed Application Scripts folder
						
						if (! [fileManager removeItemAtURL:destinationURL error:&error]) {
							NSLog(@"%s error = %@", __PRETTY_FUNCTION__, error);
						}
						else {
							BOOL success = [fileManager copyItemAtURL:sourceURL toURL:destinationURL error:&error];
							if (success) {
								NSAlert *alert = [NSAlert alertWithMessageText:@"Script Updated" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The Automation script was updated."];
								[alert runModal];
							}
						}
					}
					else {
						// the item couldn't be copied, try again
						[self performSelector:@selector(installAutomationScript:) withObject:self afterDelay:0.0];
					}
				}
			}
			else {
				// try again because the user changed the folder path
				[self performSelector:@selector(installAutomationScript:) withObject:self afterDelay:0.0];
			}
		}
	}];
}

- (IBAction)getURL:(id)sender
{
	NSUserAppleScriptTask *automationScriptTask = [self automationScriptTask];
	if (automationScriptTask) {
		NSAppleEventDescriptor *event = [self safariURLEventDescriptor];
		[automationScriptTask executeWithAppleEvent:event completionHandler:^(NSAppleEventDescriptor *resultEventDescriptor, NSError *error) {
			if (! resultEventDescriptor) {
				NSLog(@"%s AppleScript task error = %@", __PRETTY_FUNCTION__, error);
			}
			else {
				NSURL *URL = [self URLForResultEventDescriptor:resultEventDescriptor];
				// NOTE: The completion handler for the script is not run on the main thread. Before you update any UI, you'll need to get
				// on that thread by using libdispatch or performing a selector.
				[self performSelectorOnMainThread:@selector(updateURLTextFieldWithURL:) withObject:URL waitUntilDone:NO];
			}
		}];
	}
	else {
		// the task couldn't be run, so try to install the script again (it could have been manually deleted by the user)
		[self installAutomationScript:self];
	}
}

- (IBAction)setURL:(id)sender
{
	NSUserAppleScriptTask *automationScriptTask = [self automationScriptTask];
	if (automationScriptTask) {
		NSAppleEventDescriptor *event = [self setSafariURLEventDescriptorWithString:[self.URLInputTextField stringValue]];
		[automationScriptTask executeWithAppleEvent:event completionHandler:^(NSAppleEventDescriptor *resultEventDescriptor, NSError *error) {
			if (! resultEventDescriptor) {
				NSLog(@"%s AppleScript task error = %@", __PRETTY_FUNCTION__, error);
			}
		}];
	}
}

- (IBAction)getHTML:(id)sender
{
	NSUserAppleScriptTask *automationScriptTask = [self automationScriptTask];
	if (automationScriptTask) {
		NSAppleEventDescriptor *event = [self safariHTMLEventDescriptor];
		[automationScriptTask executeWithAppleEvent:event completionHandler:^(NSAppleEventDescriptor *resultEventDescriptor, NSError *error) {
			if (! resultEventDescriptor) {
				NSLog(@"%s AppleScript task error = %@", __PRETTY_FUNCTION__, error);
			}
			else {
				NSString *HTMLString = [self stringForResultEventDescriptor:resultEventDescriptor];
				[self performSelectorOnMainThread:@selector(updateHTMLTextFieldWithString:) withObject:HTMLString waitUntilDone:NO];
			}
		}];
	}
}

- (IBAction)openUserScriptsFolder:(id)sender
{
	NSError *error;
	NSURL *directoryURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
	
	[[NSWorkspace sharedWorkspace] openURL:directoryURL];
}

- (IBAction)openNetworkPreferences:(id)sender
{
	NSUserAppleScriptTask *automationScriptTask = [self automationScriptTask];
	if (automationScriptTask) {
		// wait for any previous tasks to complete before starting a new one — remember that you're blocking the main thread here!
		dispatch_semaphore_wait(self.appleScriptTaskSemaphore, DISPATCH_TIME_FOREVER);
		
		// run the script task
		NSAppleEventDescriptor *event = [self openNetworkPreferencesEventDescriptor];
		[automationScriptTask executeWithAppleEvent:event completionHandler:^(NSAppleEventDescriptor *resultEventDescriptor, NSError *error) {
			if (! resultEventDescriptor) {
				NSLog(@"%s AppleScript task error = %@", __PRETTY_FUNCTION__, error);
			}
			else {
				[self performSelectorOnMainThread:@selector(showNetworkAlert) withObject:nil waitUntilDone:NO];
			}
			
			// the task has completed, so let any pending tasks proceed
			dispatch_semaphore_signal(self.appleScriptTaskSemaphore);
		}];
	}
}

@end
