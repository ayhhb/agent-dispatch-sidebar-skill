#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong) NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];
    CGFloat sidebarWidth = 320;
    NSRect windowRect = NSMakeRect(
        screenFrame.origin.x + screenFrame.size.width - sidebarWidth,
        screenFrame.origin.y,
        sidebarWidth,
        screenFrame.size.height);

    NSUInteger styleMask = NSWindowStyleMaskTitled |
                           NSWindowStyleMaskClosable |
                           NSWindowStyleMaskMiniaturizable |
                           NSWindowStyleMaskResizable;

    self.window = [[NSWindow alloc] initWithContentRect:windowRect
                                               styleMask:styleMask
                                                 backing:NSBackingStoreBuffered
                                                   defer:NO];
    [self.window setTitle:@"__APP_NAME__"];
    [self.window setLevel:NSFloatingWindowLevel];
    [self.window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces |
                                        NSWindowCollectionBehaviorFullScreenAuxiliary];
    [self.window setReleasedWhenClosed:NO];
    [self.window setTitlebarAppearsTransparent:YES];
    [self.window setBackgroundColor:[NSColor colorWithRed:0.051 green:0.067 blue:0.090 alpha:1.0]];
    [self.window setMinSize:NSMakeSize(280, 420)];
    [self.window setMovableByWindowBackground:YES];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:config];
    [webView setValue:@NO forKey:@"drawsBackground"];
    [webView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"sidebar" ofType:@"html"];
    NSURL *url = [NSURL fileURLWithPath:htmlPath];
    [webView loadFileURL:url allowingReadAccessToURL:[url URLByDeletingLastPathComponent]];

    [self.window setContentView:webView];
    [self.window makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    if (!flag && self.window) {
        [self.window makeKeyAndOrderFront:nil];
    }
    return YES;
}

@end

int main(int argc, const char *argv[]) {
    NSApplication *app = [NSApplication sharedApplication];
    [app setDelegate:[[AppDelegate alloc] init]];
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];

    NSMenu *mainMenu = [[NSMenu alloc] init];
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    [mainMenu addItem:appMenuItem];
    NSMenu *appMenu = [[NSMenu alloc] init];
    [appMenu addItemWithTitle:@"Quit __APP_NAME__" action:@selector(terminate:) keyEquivalent:@"q"];
    [appMenuItem setSubmenu:appMenu];
    [app setMainMenu:mainMenu];

    [app activateIgnoringOtherApps:YES];
    [app run];
    return 0;
}
