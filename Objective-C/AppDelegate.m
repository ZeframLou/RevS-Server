//
//  AppDelegate.m
//  RevS Server Test
//
//  Created by Zebang Liu on 13-10-4.
//  Copyright (c) 2013年 Zebang Liu. All rights reserved.
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


#import "AppDelegate.h"
#import "RevS.h"

@protocol BackspaceDeleteTableViewDelegate <NSObject>

- (void)tableViewDidBackspaceDeleteRow:(NSInteger)row;

@end

@interface BackspaceDeleteTableView : NSTableView

@property (nonatomic,strong) id <BackspaceDeleteTableViewDelegate> backSpaceDelegate;

@end

@implementation BackspaceDeleteTableView

@synthesize backSpaceDelegate;

- (void)keyDown:(NSEvent *)theEvent
{
    unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if(key == NSDeleteCharacter)
    {
        [self deleteItem];
        return;
    }
    
    [super keyDown:theEvent];
    
}

- (void)deleteItem
{
    if ([self numberOfSelectedRows] == 0) return;
    
    NSUInteger index = [self selectedRow];
    
    [self removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationSlideRight];
    if ([backSpaceDelegate respondsToSelector:@selector(tableViewDidBackspaceDeleteRow:)]) {
        [backSpaceDelegate tableViewDidBackspaceDeleteRow:index];
    }
}

@end

@interface AppDelegate () <RSServerDelegate,NSTableViewDataSource,NSTableViewDelegate,NSTextFieldDelegate,BackspaceDeleteTableViewDelegate,RSMessengerDelegate>

@property (nonatomic,strong) NSMutableArray *arguments;
@property (nonatomic,strong) NSMutableArray *selectedClients;
@property (nonatomic,strong) RSMessenger *messenger;

@end

@implementation AppDelegate

@synthesize startSwitch,logView,messageIdentifierTextField,messageArgumentsTable,clientListTable,sendButton;
@synthesize arguments,selectedClients,messenger;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [RSServer addDelegate:self];
    arguments = [NSMutableArray array];
    selectedClients = [NSMutableArray array];
    messenger = [RSMessenger messengerWithPort:MESSAGE_PORT delegate:self];
    messageArgumentsTable.backSpaceDelegate = self;
}

- (IBAction)start:(id)sender {
    if (![RSServer isStarted]) {
        [RSServer start];
        startSwitch.title = @"Stop";
        [self updateLog:@"Server started."];
    }
    else {
        [RSServer stop];
        startSwitch.title = @"Start";
        [self updateLog:@"Server stopped."];
    }
}

- (void)updateLog:(NSString *)log
{
    [[[logView textStorage] mutableString] appendString:[log stringByAppendingString:@"\n"]];
}

- (IBAction)addArgument:(id)sender {
    [arguments addObject:@""];
    [messageArgumentsTable reloadData];
}

- (IBAction)selectAll:(id)sender {
    __block BOOL allSelected = YES;
    [clientListTable enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
        NSButton *checkBox = [rowView viewAtColumn:0];
        if (checkBox.state == NSOffState) {
            allSelected = NO;
        }
    }];
    NSUInteger state;
    if (allSelected) {
        state = NSOffState;
    }
    else {
        state = NSOnState;
    }
    [clientListTable enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
        NSButton *checkBox = [rowView viewAtColumn:0];
        checkBox.state = state;
        [self checkChanged:checkBox];
    }];
}

- (IBAction)refreshClientList:(id)sender {
    [clientListTable reloadData];
}

- (IBAction)saveLog:(id)sender {
    if (logView.string.length > 0) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setDateFormat:@"yyyy/MM/dd-HH/mm"];
        [logView.string writeToFile:[NSString stringWithFormat:@"%@/Desktop/RevS_Server_Log_%@.txt",NSHomeDirectory(),[formatter stringFromDate:[NSDate date]]] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

- (IBAction)sendMessage:(id)sender {
    for (NSString *string in selectedClients) {
        NSArray *array = [string componentsSeparatedByString:@"|"];
        NSString *publicIp = [[[array objectAtIndex:1] componentsSeparatedByString:@","] objectAtIndex:0];
        NSString *privateIp = [[[array objectAtIndex:1] componentsSeparatedByString:@","] objectAtIndex:1];
        [messenger sendUdpMessage:[RSMessenger messageWithIdentifier:messageIdentifierTextField.stringValue arguments:arguments] toHostWithPublicAddress:publicIp privateAddress:privateIp tag:0];
    }
    [self updateLog:[NSString stringWithFormat:@"Sent message with identifier:\"%@\" arguments:%@",messageIdentifierTextField.stringValue,arguments]];
}

- (void)checkChanged:(id)sender {
    NSButton *checkBox = sender;
    __block NSInteger index;
    [clientListTable enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
        NSButton *check = [rowView viewAtColumn:0];
        if ([checkBox isEqual:check]) {
            index = row;
        }
    }];
    NSData *data = [NSData dataWithContentsOfFile:IP_LIST_PATH];
    NSString *string = [NSData decryptData:data withKey:FILE_CODE];
    NSString *dataString;
    if (string.length > 0) {
        dataString = [[string componentsSeparatedByString:@";"] objectAtIndex:index];
    }
    if (checkBox.state == NSOnState) {
        [selectedClients addObject:dataString];
    }
    else {
        [selectedClients removeObject:dataString];
    }
    if (selectedClients.count == 0) {
        [sendButton setEnabled:NO];
    }
    else {
        [sendButton setEnabled:YES];
    }
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    [tableView setAllowsColumnReordering:NO];
    if ([tableView isEqual:messageArgumentsTable]) {
        NSTextField *textField = [[NSTextField alloc]init];
        textField.delegate = self;
        [textField setBordered:NO];
        [textField setEditable:YES];
        [textField setStringValue:[arguments objectAtIndex:row]];
        textField.backgroundColor = [NSColor clearColor];
        if (row == tableView.numberOfRows - 1) {
            double delayInSeconds = 0.001;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [textField selectText:self];
                [[textField currentEditor] setSelectedRange:NSMakeRange([[textField stringValue] length], 0)];
            });
        }
        return textField;
    }
    else {
        NSView *view;
        NSTextField *textField = [[NSTextField alloc]init];
        textField.delegate = self;
        [textField setBordered:NO];
        [textField setEditable:NO];
        textField.backgroundColor = [NSColor clearColor];
        
        [[textField cell] setLineBreakMode:NSLineBreakByTruncatingTail];

        NSData *data = [NSData dataWithContentsOfFile:IP_LIST_PATH];
        NSString *string = [NSData decryptData:data withKey:FILE_CODE];
        NSString *deviceId = [NSString string];
        NSString *publicIp = [NSString string];
        NSString *privateIp = [NSString string];
        if (string.length > 0) {
            NSString *dataString = [[string componentsSeparatedByString:@";"] objectAtIndex:row];
            NSArray *array = [dataString componentsSeparatedByString:@"|"];
            deviceId = [array objectAtIndex:0];
            publicIp = [[[array objectAtIndex:1] componentsSeparatedByString:@","] objectAtIndex:0];
            privateIp = [[[array objectAtIndex:1] componentsSeparatedByString:@","] objectAtIndex:1];
        }
        
        NSButton *checkBox = [[NSButton alloc] init];
        [checkBox setButtonType:NSSwitchButton];
        [checkBox setTarget:self];
        [checkBox setAction:@selector(checkChanged:)];
        
        switch ([tableView columnWithIdentifier:tableColumn.identifier]) {
            case 0:
                [tableColumn setResizingMask:NSTableColumnNoResizing];
                view = checkBox;
                break;
            case 1:
                [textField setStringValue:deviceId];
                view = textField;
                break;
            case 2:
                [textField setStringValue:publicIp];
                view = textField;
                break;
            case 3:
                [textField setStringValue:privateIp];
                view = textField;
                break;
            default:
                break;
        }
        return view;
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    if ([tableView isEqual:messageArgumentsTable]) {
        NSTableRowView *willSelectRowView = [tableView rowViewAtRow:row makeIfNecessary:NO];
        [(NSTextField *)[willSelectRowView viewAtColumn:0] setTextColor:[NSColor whiteColor]];
        if (tableView.selectedRow != -1) {
            NSTableRowView *selectedRowView = [tableView rowViewAtRow:tableView.selectedRow makeIfNecessary:NO];
            [(NSTextField *)[selectedRowView viewAtColumn:0] setTextColor:[NSColor blackColor]];
        }
        return YES;
    }
    else {
        return NO;
    }
}

- (void)tableViewDidBackspaceDeleteRow:(NSInteger)row
{
    [arguments removeObjectAtIndex:row];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    BackspaceDeleteTableView *tableView = notification.object;
    if (tableView.selectedRow == -1) {
        [tableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
            NSTextField *textField = [rowView viewAtColumn:0];
            if ([textField.textColor isEqual:[NSColor whiteColor]]) {
                [textField setTextColor:[NSColor blackColor]];
            }
        }];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger integer;
    if ([tableView isEqual:messageArgumentsTable]) {
        integer = arguments.count;
    }
    else {
        integer = [RSUtilities localPublicIpList].count;
    }
    return integer;
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)obj
{
    NSTextField *textField = obj.object;
    if ([textField isEqual:messageIdentifierTextField]) {
        if (textField.stringValue.length > 0 && selectedClients.count > 0) {
            [sendButton setEnabled:YES];
        }
        else {
            [sendButton setEnabled:NO];
        }
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    NSTextField *textField = obj.object;
    if (![textField isEqual:messageIdentifierTextField]) {
        [arguments replaceObjectAtIndex:[messageArgumentsTable rowForView:textField] withObject:textField.stringValue];
    }
}

#pragma mark - RSServerDelegate

- (void)serverDidRecieveMessageWithIdentifier:(NSString *)identifier arguments:(NSArray *)arguments
{
    [self updateLog:[NSString stringWithFormat:@"Received message with identifier \"%@\" arguments %@",identifier,arguments]];
}

@end
