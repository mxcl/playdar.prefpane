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

//TODO when launching, watch the NSTask, and say "Crashed :(" if early exit
//TODO otherwise check status of pid when window becomes key and update button
//TODO remember path that we scanned with defaults controller

#import "main.h"
#import "Sparkle/SUUpdater.h"
#import "DaemonController.h"


@implementation OrgPlaydarPreferencePane

-(NSString*)etc
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/org.playdar"];
}

static NSString* localized_number(NSUInteger n)
{
    static NSNumberFormatter* formatter = 0;
    if(!formatter) formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setFormat: @"#,###"];
    return [formatter stringFromNumber:[NSNumber numberWithInt:n]];
}

-(void)showTrackCount:(int)n
{  
    [scanning setHidden:NO];        
    [scanning setStringValue:[localized_number(n) stringByAppendingString:@" local tracks known to Playdar"]];
}

-(void)mainViewDidLoad
{
    [[popup menu] addItem:[NSMenuItem separatorItem]];
    [[[popup menu] addItemWithTitle:@"Other…" action:@selector(onSelect:) keyEquivalent:@""] setTarget:self];

    NSString* home = NSHomeDirectory();
    NSString* user_path = [[NSUserDefaults standardUserDefaults] objectForKey:@"org.playdar.MusicPath"];
    if (user_path) [self addFolder:user_path setSelected:true];
    [self addFolder:[home stringByAppendingPathComponent:@"Music"] setSelected:!user_path];
    [self addFolder:home setSelected:false];

    d = [[DaemonController alloc] initWithDelegate:self andRootDir:[[self bundle] bundlePath]];

    if ([d isRunning]) {
        [big_switch setState:NSOnState animate:false];
        [demos setHidden:false];
        [self showTrackCount:[d numFiles]];
    }

////// Sparkle
    SUUpdater* updater = [SUUpdater updaterForBundle:[self bundle]];
    [updater resetUpdateCycle];
    [updater setDelegate:self];

    if([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
        [updater checkForUpdates:self];
}

-(void)addFolder:(NSString*)path setSelected:(bool)select
{
    int const index = [[popup menu] numberOfItems]-2;
    NSMenuItem* item = [[popup menu] insertItemWithTitle:path action:nil keyEquivalent:@"" atIndex:index];
    NSImage* image = [[NSWorkspace sharedWorkspace] iconForFile:path];
    [image setSize:NSMakeSize(16, 16)];
    [item setImage:image];
    if(select) [popup selectItemAtIndex:index];
}

#define PPP_ANIMATION(x) \
    id d1 = [NSDictionary dictionaryWithObjectsAndKeys:demos, NSViewAnimationTargetKey, x, NSViewAnimationEffectKey, nil]; \
    id d2 = [NSDictionary dictionaryWithObjectsAndKeys:scanning, NSViewAnimationTargetKey, x, NSViewAnimationEffectKey, nil]; \
    id a = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:d1, d2, nil]]; \
    [a setDuration:0.45]; \
    [a setAnimationCurve:NSAnimationEaseIn]; \
    [a setAnimationBlockingMode:NSAnimationBlocking]; \
    [a startAnimation]; \
    [a release];

-(void)fadeInDemoButton
{
    if([demos isHidden]){
        [demos setHidden:false];
        PPP_ANIMATION(NSViewAnimationFadeInEffect)
    }
}

-(void)fadeOutDemoButton
{
    if(![demos isHidden]){
        PPP_ANIMATION(NSViewAnimationFadeOutEffect)
        [demos setHidden:true];
    }
}

-(void)scan
{
    @try {
        count = 0;
        
        NSPipe* pipe = [NSPipe pipe];
        scanner_read_handle = [pipe fileHandleForReading];
        [scanner_read_handle readInBackgroundAndNotify];

        scanner_task = [[NSTask alloc] init];
        scanner_task.launchPath = [d playdarctl];
        scanner_task.arguments = [NSArray arrayWithObjects:@"scan", [popup titleOfSelectedItem], nil];
        [scanner_task setStandardOutput:pipe];

        [scanner_task launch];

        [popup setEnabled:false];
        [on_spinner startAnimation:self];
        [scanning setStringValue:@"Scanning…"];
        [scanning setHidden:NO];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(scanProgress:)
                                                     name:NSFileHandleReadCompletionNotification
                                                   object:scanner_read_handle];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(scanComplete:)
                                                     name:NSTaskDidTerminateNotification
                                                   object:scanner_task];
        [on_spinner startAnimation:self];
    }
    @catch (NSException* e)
    {
        NSRunCriticalAlertPanel(@"Could not start scan", [e reason], nil, nil, nil);
    }
}

-(void)scanProgress:(NSNotification*)note
{
    NSData* data = [[note userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    // -1 because the string always ends with a \n
    count += [[string componentsSeparatedByString:@"\n"] count] - 1;

    [scanning setStringValue:[localized_number(count) stringByAppendingString:@" files scanned"]];

    if([scanner_task isRunning])
        [scanner_read_handle readInBackgroundAndNotify];
}

-(void)scanComplete:(NSNotification*)note
{
    int n = [d numFiles];
    [on_spinner stopAnimation:self];
    [popup setEnabled:true];
    
    if(n > 0) {
        [self showTrackCount:n];
        [self fadeInDemoButton];
    }else{
        // prolly because playdar was turned off
        [scanning setHidden:true];
    }
}

-(NSString*)menuItemAppPath
{
    return [[[self bundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/Playdar.app"];
}

-(void)startAtLogin:(bool)start_at_login
{
    //TODO Using FsRefs is better, however I did that with Audioscrobbler.app and
    // it never seemed to work properly IMO
    
    LSSharedFileListRef login_items_ref = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if(login_items_ref == NULL) return;
    
    CFURLRef app_url = (CFURLRef)[NSURL fileURLWithPath:[self menuItemAppPath]];
    
    LSSharedFileListItemRef item;
    if(start_at_login){
        item = LSSharedFileListInsertItemURL(login_items_ref,
                                             kLSSharedFileListItemLast,
                                             NULL, // name
                                             NULL, // icon
                                             app_url,
                                             NULL, NULL);
        if(item)
            CFRelease(item);
    }else{
        UInt32 seed;
        NSArray *items = [(NSArray*)LSSharedFileListCopySnapshot(login_items_ref, &seed) autorelease];
        for (id id in items){
            CFURLRef url;
            LSSharedFileListItemRef item = (LSSharedFileListItemRef)id;
            if (LSSharedFileListItemResolve(item, 0, &url, NULL) == noErr){
                if ([(NSURL*)url isEqual:(NSURL*)app_url]){
                    LSSharedFileListItemRemove(login_items_ref, item);
                    break;
                }
                if(url)
                    CFRelease(url);
            }
        }
    }
    
    CFRelease(login_items_ref);
}

-(void)playdarIsStarting
{
    [on_spinner startAnimation:self];
    [big_switch setState:NSOnState];
}

-(void)playdarFailedToStart:(NSString*)emsg
{
    NSBeginAlertSheet(@"Could not start Playdar",
                      nil, nil, nil,
                      [[self mainView] window], self,
                      nil, nil, nil,
                      emsg );

    [self startAtLogin:NO];
    [big_switch setState:NSOffState]; //TODO do both simultaneously
    [self fadeOutDemoButton];         //TODO this one too see
    [on_spinner stopAnimation:self];
}

-(void)playdarStarted:(NSNumber*)n
{
    int num_files = [n intValue];

    [self startAtLogin:YES];
    [big_switch setState:NSOnState];

    if(num_files == 0)
        [self scan];
    else {
        [self showTrackCount:num_files];
        [on_spinner stopAnimation:self];
        [self fadeInDemoButton];
    }
}

-(void)playdarIsStopping
{
    [big_switch setState:NSOffState];
    [off_spinner startAnimation:self];
    [on_spinner stopAnimation:self];
}

-(void)playdarFailedToStop:(NSString*)emsg
{
    NSBeginAlertSheet(@"Could not stop Playdar",
                      nil, nil, nil,
                      [[self mainView] window], self,
                      nil, nil, nil,
                      emsg);
}

-(void)playdarStopped
{
    [NSObject cancelPreviousPerformRequestsWithTarget:off_spinner];

    [big_switch setState:NSOffState];
    [on_spinner stopAnimation:self];
    [off_spinner stopAnimation:self];
    [self fadeOutDemoButton];
    [self startAtLogin:false];
}

-(void)onEnable:(id)sender
{
    if ([big_switch state] == NSOffState)
        [d stop];
    else if (NSAlternateKeyMask & [[NSApp currentEvent] modifierFlags])
        [d startInTerminal];
    else
        [d start];
}

////// Directory selector
-(void)onSelect:(id)sender
{
    // return if not the Select... item
    if([popup indexOfSelectedItem] != [popup numberOfItems]-1) return;
    
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel beginSheetForDirectory:nil 
                             file:nil 
                   modalForWindow:[[self mainView] window]
                    modalDelegate:self
                   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                      contextInfo:nil];
}

-(void)openPanelDidEnd:(NSOpenPanel*)panel
            returnCode:(int)returnCode
           contextInfo:(void*)contextInfo 
{
    if(returnCode == NSOKButton) {
        NSString* path = [panel filename];
        [self addFolder:path setSelected:true];
        [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"org.playdar.MusicPath"];
    } else
        [popup selectItemAtIndex:0];
}
////// Directory selector

-(IBAction)onHelp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wiki.github.com/RJ/playdar-core/"]];
}

-(IBAction)onAdvanced:(id)sender
{
    [NSApp beginSheet:advanced_window
       modalForWindow:[[self mainView] window]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
}

-(IBAction)onCloseAdvanced:(id)sender
{
    [advanced_window orderOut:nil];
    [NSApp endSheet:advanced_window];
}

-(NSString*)playdarModules
{
    return [[[self bundle] bundlePath] stringByAppendingPathComponent:@"playdar_modules"];
}

static bool has_conf_files(NSString* path)
{
    for (NSString* f in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL])
        if ([f hasSuffix:@".conf"])
            return true;
    return false;
}

-(IBAction)onEditConfigFile:(id)sender;
{
    NSString* conf = [self etc];
    
    if (!has_conf_files(conf)) {
        NSTask * task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/tar";
        task.arguments = [NSArray arrayWithObjects:@"xjf", [[self bundle] pathForResource:@"confs" ofType:@"tbz"], nil];
        task.currentDirectoryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences"];
        [task launch];
        [task waitUntilExit];

        if (task.terminationStatus != 0)
            NSRunCriticalAlertPanel(@"Could not create configuration files", @"Sorry about that old boy.", nil, nil, nil);
    }
    
    #define OPEN(x) [[NSWorkspace sharedWorkspace] openFile:conf withApplication:x]
    if (!OPEN(@"TextMate")) OPEN(@"Finder");
}

-(IBAction)onDemos:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://playdar.org/demos/"]];
}

-(IBAction)onViewStatus:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost:60210"]];
}

-(IBAction)onShowMenuItem:(id)sender
{
    bool state = [sender state] == NSOnState;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:state forKey:@"org.playdar.ShowMenuItem"];
    [defaults synchronize]; // so we ensure the menu item can read the setting
    
    if (state) {
        NSString* app = [self menuItemAppPath];
        [[NSWorkspace sharedWorkspace] openFile:app withApplication:nil andDeactivate:NO];
    } else {
        [NSTask launchedTaskWithLaunchPath:@"/usr/bin/osascript" arguments:[NSArray arrayWithObjects:@"-e", @"tell application \"Playdar\" to quit", nil]];
    }
}

@end


@implementation OrgPlaydarPreferencePane(SUUpdaterDelegateInformalProtocol)

-(void)updaterWillRelaunchApplication:(SUUpdater*)updater
{
    [d stop];
}

-(NSString*)pathToRelaunchForUpdater:(SUUpdater*)updater
{
    return [[NSBundle mainBundle] bundlePath];
}

@end
