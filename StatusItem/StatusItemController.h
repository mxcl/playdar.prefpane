#import <Cocoa/Cocoa.h>

@class DaemonController;

@interface StatusItemController : NSObject
{
    NSStatusItem* status_item;
    IBOutlet NSMenu* menu;
    IBOutlet NSMenuItem* toggle;
    DaemonController* d;
}

-(IBAction)preferences:(id)sender;
-(IBAction)togglePlaydar:(id)sender;
-(IBAction)viewLog:(id)sender;
-(IBAction)viewStatus:(id)sender;

@end
