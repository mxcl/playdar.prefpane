/*
 Created on 28/02/2009
 Copyright 2009 Max Howell <max@methylblue.com>
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <PreferencePanes/PreferencePanes.h>
#import "MBSliderButton.h"

// long class name is because we get loaded into System Preferences process, so 
// we are required to be ultra verbose
// http://developer.apple.com/documentation/UserExperience/Conceptual/PreferencePanes/Tasks/Conflicts.html
@interface OrgPlaydarPreferencePane : NSPreferencePane 
{
    IBOutlet NSPopUpButton* popup;
    IBOutlet MBSliderButton* big_switch;
    IBOutlet NSButton* demos;
    IBOutlet NSWindow* advanced_window;
    IBOutlet NSProgressIndicator* spinner;
    IBOutlet NSProgressIndicator* scan_spinner;
    IBOutlet NSTextField* scanning;
    
    NSTask* daemon_task;
    NSTask* scanner_task;
    NSTimer* poll_timer;
    NSTimer* check_startup_status_timer;
    pid_t pid;
}

-(void)mainViewDidLoad;
-(void)addFolder:(NSString*)path setSelected:(bool)select;

-(void)openPanelDidEnd:(NSOpenPanel*)panel
            returnCode:(int)returnCode
           contextInfo:(void*)contextInfo;

-(IBAction)onSelect:(id)sender;
-(IBAction)onEnable:(id)sender;
-(IBAction)onDemos:(id)sender;
-(IBAction)onHelp:(id)sender;
-(IBAction)onAdvanced:(id)sender;
-(IBAction)onEditConfigFile:(id)sender;
-(IBAction)onViewStatus:(id)sender;
-(IBAction)onCloseAdvanced:(id)sender;

@end
