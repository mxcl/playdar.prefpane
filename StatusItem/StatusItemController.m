#import "StatusItemController.h"
#import "DaemonController.h"

static NSString* prefpane_path()
{
    return [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"../../../"];
}


@implementation StatusItemController

-(void)setState:(bool)on
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

    d = [[DaemonController alloc] initWithDelegate:self andRootDir:prefpane_path()];

    [self setState:[d isRunning]];
}

-(void)preferences:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:prefpane_path()];
}

-(void)togglePlaydar:(id)sender
{    
    if ([d isRunning]){
        [self setState:false];
        [d stop];
    }else{
        [self setState:true];
        [d start];
    }
}

-(void)playdarIsStarting
{}
-(void)playdarIsStopping
{}

-(void)playdarStarted:(NSNumber*)num_files
{
    [self setState:true];
}

-(void)playdarStopped
{
    [self setState:false];
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
