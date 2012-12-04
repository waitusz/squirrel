
#import "SquirrelApplicationDelegate.h"
#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import <InputMethodKit/InputMethodKit.h>
#import <string.h>
#import <rime_api.h>

// Each input method needs a unique connection name.
// Note that periods and spaces are not allowed in the connection name.
const NSString *kConnectionName = @"Squirrel_1_Connection";

//let this be a global so our application controller delegate can access it easily
IMKServer* g_server;

int main(int argc, char *argv[])
{
  RimeSetupLogging("rime.squirrel");
  
  if (argc > 1 && !strcmp("--build", argv[1])) {
    // notification
    [GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Squirrel", nil)
                                description:NSLocalizedString(@"Deploying Rime for updates.", nil)
                           notificationName:@"Squirrel"
                                   iconData:[NSData dataWithData:[[NSImage imageNamed:@"zhung"] TIFFRepresentation]]
                                   priority:0
                                   isSticky:NO
                               clickContext:nil
                                 identifier:@"deploy"];
    // build all schemas in current directory
    RimeDeployerInitialize(NULL);
    return RimeDeployWorkspace() ? 0 : 1;
  }
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // find the bundle identifier and then initialize the input method server
  g_server = [[IMKServer alloc] initWithName: (NSString *) kConnectionName
                            bundleIdentifier: [[NSBundle mainBundle] bundleIdentifier]];
  
  // load the bundle explicitly because in this case the input method is a
  // background only application
  [NSBundle loadNibNamed: @"MainMenu" owner: [NSApplication sharedApplication]];
  
  // opencc will be configured with relative dictionary paths
  [[NSFileManager defaultManager] changeCurrentDirectoryPath:[[NSBundle mainBundle] sharedSupportPath]];
  
  if ([[NSApp delegate] problematicLaunchDetected]) {
    NSLog(@"Problematic launch detected!");
    NSArray* args = [NSArray arrayWithObjects:@"Problematic launch detected! \
                     Squirrel may be suffering a crash due to imporper configuration. \
                     Revert previous modifications to see if the problem recurs.", nil];
    [NSTask launchedTaskWithLaunchPath:@"/usr/bin/say" arguments:args];
  }
  else {
    [[NSApp delegate] startRimeWithFullCheck:NO];
    [[NSApp delegate] loadSquirrelConfig];
    NSLog(@"Squirrel reporting!");
  }
  
  // finally run everything
  [[NSApplication sharedApplication] run];
  
  NSLog(@"Squirrel is quitting...");
  RimeFinalize();
  
  [g_server release];
  [pool release];
  return 0;
}

