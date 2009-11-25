#import "DaemonController.h"
#import <sys/sysctl.h>

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

#define START_POLL poll_timer = [NSTimer scheduledTimerWithTimeInterval:0.33 target:self selector:@selector(poll:) userInfo:nil repeats:true];



@implementation DaemonController

-(id)initWithDelegate:(id)d andRootDir:(NSString*)r
{
    delegate = [d retain];
    root = [r retain];

    if(pid = playdar_pid())
        kqueue_watch_pid(pid, self); // watch the pid for termination
    else
        START_POLL;

    return self;
}

-(bool)isRunning
{
    return daemon_task && [daemon_task isRunning] || (pid = playdar_pid());
}

-(NSString*)playdarctl
{
    return [root stringByAppendingPathComponent:@"bin/playdarctl"];
}

-(void)daemonTerminated:(NSNotification*)note
{    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:daemon_task];
    
    daemon_task = nil;
    pid = 0;

    START_POLL;
    
    [delegate performSelector:@selector(playdarStopped)];
}

-(void)stop
{
    NSTask* task = [[NSTask alloc] init];
    task.launchPath = [self playdarctl];
    task.arguments = [NSArray arrayWithObjects:@"stop", nil];
    
    [delegate performSelector:@selector(playdarIsStopping)];
    
    [task launch];
    [task waitUntilExit];
    
    if (task.terminationStatus == 0)
        // the kqueue event will tell us when the process exits
        return;
    
    // playdarctl failed to stop the daemon, so it's time to be more forceful
    if(daemon_task)
        [daemon_task terminate];
    else if (pid = playdar_pid() == 0){
        // actually we weren't even running in the first place
        START_POLL
        [delegate performSelector:@selector(playdarStopped)];
    }else if (kill(pid, SIGTERM) == -1 && errno != ESRCH)
        [delegate performSelector:@selector(playdarFailedToStop) withObject:@"Perhaps you don't have the right permissions?"];
}

-(void)initDaemonTask
{
    [poll_timer invalidate];
    poll_timer = nil;

    [delegate performSelector:@selector(playdarIsStarting)];
    
    daemon_task = [[NSTask alloc] init];
}

-(void)failedToStartDaemonTask
{
    NSMutableString* msg = [@"The file at “" mutableCopy];
    [msg appendString:daemon_task.launchPath];
    [msg appendString:@"” could not be executed."];
    
    [delegate performSelector:@selector(playdarFailedToStart:) withObject:msg];

    daemon_task = nil;
    [msg release];
}

-(void)start
{
    @try {       
        [self initDaemonTask];
        daemon_task.launchPath = [self playdarctl];
        daemon_task.arguments = [NSArray arrayWithObject:@"start-exec"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(daemonTerminated:)
                                                     name:NSTaskDidTerminateNotification
                                                   object:daemon_task];
        [daemon_task launch];
        pid = daemon_task.processIdentifier;
        
        #define CHECK_READY_FOR_SCAN \
            [self performSelector:@selector(checkReadyForScan) withObject:nil afterDelay:0.2];
        
        CHECK_READY_FOR_SCAN
    }
    @catch (NSException* e) {
        [self failedToStartDaemonTask];
    }
}

-(void)startInTerminal
{
    NSMutableString* script = [@"tell application \"Terminal\" to do script \"" mutableCopy];
    [script appendString:root];
    [script appendString:@"/bin/playdarctrl start-debug; exit\""];
    
    @try {
        [self initDaemonTask];
        daemon_task.launchPath = @"/usr/bin/osascript";
        daemon_task.arguments = [NSArray arrayWithObjects:@"-e", script, nil];
        daemon_task.environment = [NSDictionary dictionaryWithObject:root forKey:@"PLAYDAR_ROOT"];
        [daemon_task launch];
        [daemon_task waitUntilExit];
        
        daemon_task = nil;
        
        CHECK_READY_FOR_SCAN
    }
    @catch (NSException* e) {
        [self failedToStartDaemonTask];
    }
     
    [script release];
}

-(void)checkReadyForScan
{
    int const n = [self numFiles];
    
    if (n < 0)
        CHECK_READY_FOR_SCAN
    else {
        if (!pid) // started via Terminal route perhaps
            kqueue_watch_pid(pid = playdar_pid(), self);
        [delegate performSelector:@selector(playdarStarted:) withObject:[NSNumber numberWithInt:n]];
    }
}

-(void)poll:(NSTimer*)t
{
    if (pid = playdar_pid() == 0) return;
    
    [delegate performSelector:@selector(playdarIsStarting)];
    [poll_timer invalidate];
    poll_timer = nil;
    kqueue_watch_pid(pid, self);
    [self checkReadyForScan];
}

/////////////////////////////////////////////////////////////////////////// misc
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

@end
