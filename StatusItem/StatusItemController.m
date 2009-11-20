//
//  StatusItemController.m
//  Playdar.prefPane
//
//  Created by Max Howell on 18/11/2009.
//  Copyright 2009 Methylblue. All rights reserved.
//

#import "StatusItemController.h"

static NSString* prefpane_path()
{
    return [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"../../../"];
}

static bool playdarctl(NSString* cmd)
{
    NSString* path = [prefpane_path() stringByAppendingPathComponent:@"bin/playdarctl"];
    NSTask* task = [NSTask launchedTaskWithLaunchPath:path arguments:[NSArray arrayWithObject:cmd]];
    [task waitUntilExit];
    return task.terminationStatus == 0;
}


@implementation StatusItemController

-(void)reflectState
{
    NSString* s = on ? @"Turn Playdar Off" : @"Turn Playdar On";
    NSString* image = on ? @"on.png" : @"off.png";
    [toggle setTitle:s];
    [status_item setImage:[NSImage imageNamed:image]];
}

-(void)awakeFromNib
{   
    status_item = [[[NSStatusBar systemStatusBar] statusItemWithLength:25] retain];
    [status_item setHighlightMode:YES];

    [status_item setAlternateImage:[NSImage imageNamed:@"pressed.png"]];
    [status_item setEnabled:YES];
    [status_item setMenu:menu];
    
    on = playdarctl(@"ping");
    [self reflectState];
}

-(void)preferences:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:prefpane_path()];
}

-(void)togglePlaydar:(id)sender
{    
    if (playdarctl(on ? @"stop" : @"start")) {
        on = !on;
        [self reflectState];
    }
}

-(void)viewLog:(id)sender
{
    NSString* path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/playdar.log"];
    [[NSWorkspace sharedWorkspace] openFile:path];
}

-(void)viewStatus:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost:60210"]];
}

@end
