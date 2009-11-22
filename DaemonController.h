#import <Cocoa/Cocoa.h>

@interface DaemonController : NSObject
{
    NSString* root;
    id delegate;
    
    NSTask* daemon_task;
    NSTimer* poll_timer;
    NSTimer* check_startup_status_timer;
    pid_t pid;    
}

-(id)initWithDelegate:(id)delegate andRootDir:(NSString*)path;

-(void)start;
-(void)startInTerminal;
-(void)stop;

-(bool)isRunning;

-(NSString*)playdarctl;
-(int)numFiles;

@end
