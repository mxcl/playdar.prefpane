//
//  StatusItemController.h
//  Playdar.prefPane
//
//  Created by Max Howell on 18/11/2009.
//  Copyright 2009 Methylblue. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface StatusItemController : NSObject
{
    NSStatusItem* status_item;
    IBOutlet NSMenu* menu;
    IBOutlet NSMenuItem* toggle;
    bool on;
}

-(IBAction)preferences:(id)sender;
-(IBAction)togglePlaydar:(id)sender;
-(IBAction)viewLog:(id)sender;
-(IBAction)viewStatus:(id)sender;

@end
