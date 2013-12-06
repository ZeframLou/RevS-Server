//
//  AppDelegate.h
//  RevS Server Test
//
//  Created by Zebang Liu on 13-10-4.
//  Copyright (c) 2013 Zebang Liu. All rights reserved.
//  Contact: the.great.lzbdd@gmail.com
/*
 This file is part of RevS Server.
 
 RevS is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 RevS is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with RevS.  If not, see <http://www.gnu.org/licenses/>.
 */


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
