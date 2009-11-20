#import <Cocoa/Cocoa.h>

static bool show_menu_item()
{
    NSDictionary* dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.systempreferences"];
    NSNumber* num = [dict objectForKey:@"org.playdar.ShowMenuItem"];
    return [num boolValue];
}

static void remove_one_path_component(char* filename)
{
    int x;
    for (x = strlen(filename) - 1; x; --x)
        if (filename[x] == '/') {
            x++; // trailing slash pls
            break;
        }
    filename[x] = '\0';
}

static int launch_daemon(const char* argv1)
{
    char path[1024];
    strcpy(path, argv1);
    remove_one_path_component(path);
    strcat(path, "../../../../../bin/playdarctl");
    execl(path, "playdarctl", "start", NULL);
    return -1;
}

int main(int argc, const char **argv)
{
    [[NSAutoreleasePool alloc] init]; // avoid ugly warning in console.log
    
    if (show_menu_item())
        return NSApplicationMain(argc, argv);
    else
        return launch_daemon(*argv);
}
