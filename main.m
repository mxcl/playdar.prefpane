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
#include <Sparkle/SUUpdater.h>
#include <sys/sysctl.h>


/** returns the pid of the running playdar instance, or 0 if not found */
static pid_t playdar_pid()
{
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    struct kinfo_proc *info;
    size_t N;
    pid_t pid = 0;
    
    if(sysctl(mib, 3, NULL, &N, NULL, 0) < 0)
        return 0; //wrong but unlikely
    if(!(info = NSZoneMalloc(NULL, N)))
        return 0; //wrong but unlikely
    if(sysctl(mib, 3, info, &N, NULL, 0) < 0)
        goto end;

    N = N / sizeof(struct kinfo_proc);
    for(size_t i = 0; i < N; i++)
        if(strcmp(info[i].kp_proc.p_comm, "playdar.smp") == 0)
            { pid = info[i].kp_proc.p_pid; break; }
end:
    NSZoneFree(NULL, info);
    return pid;
}

static void kqueue_termination_callback(CFFileDescriptorRef f, CFOptionFlags callBackTypes, void* self)
{
    [(id)self performSelector:@selector(daemonTerminated:) withObject:nil];
}

static inline void kqueue_watch_pid(pid_t pid, id self)
{
    int                     kq;
    struct kevent           changes;
    CFFileDescriptorContext context = { 0, self, NULL, NULL, NULL };
    CFRunLoopSourceRef      rls;

    // Create the kqueue and set it up to watch for SIGCHLD. Use the 
    // new-in-10.5 EV_RECEIPT flag to ensure that we get what we expect.

    kq = kqueue();

    EV_SET(&changes, pid, EVFILT_PROC, EV_ADD | EV_RECEIPT, NOTE_EXIT, 0, NULL);
    (void) kevent(kq, &changes, 1, &changes, 1, NULL);

    // Wrap the kqueue in a CFFileDescriptor (new in Mac OS X 10.5!). Then 
    // create a run-loop source from the CFFileDescriptor and add that to the 
    // runloop.
    
    CFFileDescriptorRef ref;
    ref = CFFileDescriptorCreate(NULL, kq, true, kqueue_termination_callback, &context);
    rls = CFFileDescriptorCreateRunLoopSource(NULL, ref, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
    CFRelease(rls);
    
    CFFileDescriptorEnableCallBacks(ref, kCFFileDescriptorReadCallBack);
}

#define START_POLL poll_timer = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(poll:) userInfo:nil repeats:true];


@implementation OrgPlaydarPreferencePane

-(NSString*)startScriptPath
{
    return [[[self bundle] bundlePath] stringByAppendingPathComponent:@"Contents/MacOS/erlexec_playdar"];
}

-(NSString*)playdarctl
{
    return [[[self bundle] bundlePath] stringByAppendingPathComponent:@"bin/playdarctl"];
}

-(NSString*)playdarConfDir
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/org.playdar"];
}

-(int)numFiles
{
    NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath:[self playdarctl]];
    [task setArguments:[NSArray arrayWithObject:@"numfiles"]];
    [task setStandardOutput:[NSPipe pipe]]; 
    [task launch];
    [task waitUntilExit];
    
    // if not zero then we library module isn't ready yet
    if (task.terminationStatus != 0)
        return -1;
    
    NSData* data = [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] intValue];
}

-(void)showTrackCount:(int)n
{
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setFormat: @"#,###"];
    NSString* tracks = [formatter stringFromNumber:[NSNumber numberWithInt:n]];
    [formatter release];
    
    [scanning setHidden:NO];        
    [scanning setStringValue:[tracks stringByAppendingString:@" local tracks known to Playdar"]];
}

-(void)mainViewDidLoad
{   
    [[popup menu] addItem:[NSMenuItem separatorItem]];
    [[[popup menu] addItemWithTitle:@"Other…" action:@selector(onSelect:) keyEquivalent:@""] setTarget:self];

    NSString* home = NSHomeDirectory();
    [self addFolder:[home stringByAppendingPathComponent:@"Music"] setSelected:true];
    [self addFolder:home setSelected:false];

    pid = playdar_pid();
    if(pid){
        kqueue_watch_pid(pid, self); // watch the pid for termination
        [big_switch setState:NSOnState];
        [demos setHidden:false];
        [self showTrackCount:[self numFiles]];
    }
    else
        START_POLL;
    
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
    [demos setHidden:false];
    PPP_ANIMATION(NSViewAnimationFadeInEffect)
}

-(void)fadeOutDemoButton
{
    PPP_ANIMATION(NSViewAnimationFadeOutEffect)
    [demos setHidden:true];
}

-(void)scan
{
    @try {
        scanner_task = [[NSTask alloc] init];
        scanner_task.launchPath = [self playdarctl];
        scanner_task.arguments = [NSArray arrayWithObjects:@"scan", [popup titleOfSelectedItem], nil];
        [scanner_task launch];

        [scan_spinner startAnimation:self];
        [scanning setStringValue:@"Scanning…"];
        [scanning setHidden:NO];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(scanComplete:)
                                                     name:NSTaskDidTerminateNotification
                                                   object:scanner_task];

        [scan_spinner startAnimation:self];
    }
    @catch (NSException* e)
    {
        NSRunCriticalAlertPanel(@"Could not start scan", [e reason], nil, nil, nil);
    }
}

-(void)scanComplete:(NSNotification*)note
{
    [self showTrackCount:[self numFiles]];
    [scan_spinner stopAnimation:self];
    [self fadeInDemoButton];
}

-(void)poll:(NSTimer*)_poll_timer
{
    if(pid = playdar_pid()){
        [poll_timer invalidate];
        poll_timer = nil;
        kqueue_watch_pid(pid, self);
        [big_switch setState:NSOnState];
    }
}

-(void)stop
{
    NSTask* task = [[NSTask alloc] init];
    task.launchPath = [self playdarctl];
    task.arguments = [NSArray arrayWithObjects:@"stop", nil];

    [spinner startAnimation:self];
    [task launch];
    [task waitUntilExit];
    
    if (task.terminationStatus == 0) {
        daemon_task = nil;
        [spinner stopAnimation:self];
        [self fadeOutDemoButton];
        return;
    }

    if(daemon_task)
        [daemon_task terminate];
    else if(pid == 0)
        ; // state machine error!
    else if(kill(pid, SIGKILL) == -1 && errno != ESRCH){
        [big_switch setState:NSOnState];
        NSRunCriticalAlertPanel(@"Could not kill daemon",
                                @"Perhaps you don't have the right permissions?", nil, nil, nil);
    }else{
        // the kqueue event will tell us when the process exits
    }    
}

-(void)start
{
    daemon_task = [[NSTask alloc] init];
    [daemon_task setLaunchPath:[self startScriptPath]];
    [daemon_task setArguments:[NSArray arrayWithObject:@"-d"]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(daemonTerminated:)
                                                 name:NSTaskDidTerminateNotification
                                               object:daemon_task];
    [daemon_task launch];
    pid = [daemon_task processIdentifier];

    [scan_spinner startAnimation:self];

    #define CHECK_READY_FOR_SCAN \
        [self performSelector:@selector(checkReadyForScan) withObject:nil afterDelay:0.2];

    CHECK_READY_FOR_SCAN
}

-(void)checkReadyForScan
{
    int const n = [self numFiles];
    
    if (n < 0) {
        CHECK_READY_FOR_SCAN
        [scanning setHidden:NO];
        [scanning setStringValue:@"Playdar is starting up…"];
    } else if (n == 0) {
        [self scan];
    } else {
        [self showTrackCount:n];
        [scan_spinner stopAnimation:self];
        [self fadeInDemoButton];
    }
}

-(void)startInTerminal
{
    daemon_task = [[NSTask alloc] init];
    [daemon_task setLaunchPath:@"/usr/bin/open"];
    [daemon_task setArguments:[NSArray arrayWithObjects:[self startScriptPath], @"-aTerminal", nil]];
    [daemon_task launch];

    pid = -100; //HACK
    [daemon_task waitUntilExit];
    pid = playdar_pid();
    daemon_task = nil;

    if(pid)
        kqueue_watch_pid(pid, self);
    else
        [big_switch setState:NSOffState]; 
}

-(void)onEnable:(id)sender
{
    if ([big_switch state] == NSOffState) {
        [self stop];
        return;
    }

    [poll_timer invalidate];
    poll_timer=nil;
    
    pid = playdar_pid();
    
    if(!pid){
        @try{
            if(NSAlternateKeyMask & [[NSApp currentEvent] modifierFlags])
                [self startInTerminal];
            else
                [self start];
        }
        @catch(NSException* e)
        {
            NSString* msg = @"The file at “";
            msg = [msg stringByAppendingString:[daemon_task launchPath]];
            msg = [msg stringByAppendingString:@"” could not be executed."];
            
            NSBeginAlertSheet(@"Could not start Playdar",
                              nil, nil, nil,
                              [[self mainView] window],
                              self,
                              nil, nil,
                              nil,
                              msg );
            daemon_task = nil;
        }
    }else{
        // unexpectedly there is already a playdar instance running!
        kqueue_watch_pid(pid, self);
    }
}

-(void)daemonTerminated:(NSNotification*)note
{  
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSTaskDidTerminateNotification 
                                                  object:daemon_task];

    daemon_task = nil;
    pid = 0;
        
    [NSObject cancelPreviousPerformRequestsWithTarget:spinner];
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // FIXME a bit stupid no?
    [spinner stopAnimation:self];
    [scan_spinner stopAnimation:self];
    [self fadeOutDemoButton];
    [big_switch setState:NSOffState];
    [big_switch setEnabled:true];
    START_POLL;
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
        [self addFolder:[panel filename] setSelected:true];
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

-(IBAction)onEditConfigFile:(id)sender;
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* conf = [self playdarConfDir];
    
    if (![fm fileExistsAtPath:conf]) {       
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

@end


@implementation OrgPlaydarPreferencePane(SUUpdaterDelegateInformalProtocol)

-(void)updaterWillRelaunchApplication:(SUUpdater*)updater
{
    if(pid) kill(pid, SIGKILL);
}

-(NSString*)pathToRelaunchForUpdater:(SUUpdater*)updater
{
    return [[NSBundle mainBundle] bundlePath];
}

@end
