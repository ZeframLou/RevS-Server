//
//  AppDelegate.h
//  RevS Server Test
//
//  Created by lzbdd on 13-10-4.
//  Copyright (c) 2013年 lzbdd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BackspaceDeleteTableView;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSButton *startSwitch;
@property (strong) IBOutlet NSTextView *logView;

//Send message window
@property (strong) IBOutlet NSTextField *messageIdentifierTextField;
@property (strong) IBOutlet BackspaceDeleteTableView *messageArgumentsTable;
@property (strong) IBOutlet NSTableView *clientListTable;
@property (strong) IBOutlet NSButton *sendButton;


@end
