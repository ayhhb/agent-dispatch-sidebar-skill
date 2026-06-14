# Agent 调度侧边栏 · 从零到运行 · 最简路径

## 结论先行

| 尝试 | 技术 | 结果 | 失败原因 |
|------|------|------|----------|
| 1 | Safari + osascript 弹窗 | ❌ | 无 Dock 图标，无法最小化到程序坞 |
| 2 | Python tkinter (系统 3.9) | ❌ | Tk 8.6 无法创建窗口：macOS SDK 版本检查失败 |
| 3 | Python tkinter (venv 3.11, Tk 9.0) | ❌ 半成功 | 窗口能显示，但 `MouseWheel` 事件完全不触发，双指滚动作废 |
| 4 | Swift + WKWebView | ❌ | SDK/toolchain 版本不匹配，无法编译 |
| 5 | JXA (JavaScript for Automation) | ❌ | `NSObject.extend` 不可用，窗口渲染异常 |
| 6 | **Objective-C + WKWebView** | ✅ | 原生 Mach-O .app，系统级滚动，Dock 图标，一切正常 |

> **核心教训**：macOS 上做桌面工具，**不要用 tkinter**，**不要用 JXA**。ObjC + WebView 是最稳的。

---

## 最终方案：三文件即用

```
~/Desktop/Agent调度.app/
└── Contents/
    ├── Info.plist          ← 应用元数据
    ├── MacOS/
    │   └── Agent调度        ← 编译后的 Mach-O 二进制
    └── Resources/
        └── sidebar.html     ← 侧边栏 UI（可随意改）
```

### 文件 1：`Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Agent调度</string>
    <key>CFBundleIdentifier</key>
    <string>com.jerry.agent-sidebar</string>
    <key>CFBundleName</key>
    <string>Agent调度</string>
    <key>CFBundleDisplayName</key>
    <string>Agent调度</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
```

### 文件 2：`main.m`（编译为 `Agent调度`）

```objc
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong) NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];
    CGFloat sidebarWidth = 300;
    NSRect windowRect = NSMakeRect(
        screenFrame.origin.x + screenFrame.size.width - sidebarWidth,
        screenFrame.origin.y, sidebarWidth, screenFrame.size.height);

    NSUInteger styleMask = NSWindowStyleMaskTitled |
                           NSWindowStyleMaskClosable |
                           NSWindowStyleMaskMiniaturizable |
                           NSWindowStyleMaskResizable;

    self.window = [[NSWindow alloc] initWithContentRect:windowRect
                                               styleMask:styleMask
                                                 backing:NSBackingStoreBuffered defer:NO];
    [self.window setTitle:@"Agent 调度"];
    [self.window setLevel:NSFloatingWindowLevel];
    [self.window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces |
                                        NSWindowCollectionBehaviorFullScreenAuxiliary];
    [self.window setReleasedWhenClosed:NO];
    [self.window setTitlebarAppearsTransparent:YES];
    [self.window setBackgroundColor:[NSColor colorWithRed:0.051 green:0.067 blue:0.090 alpha:1.0]];
    [self.window setMinSize:NSMakeSize(260, 400)];
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
    if (!flag && self.window) [self.window makeKeyAndOrderFront:nil];
    return YES;
}

@end

int main(int argc, const char * argv[]) {
    NSApplication *app = [NSApplication sharedApplication];
    [app setDelegate:[[AppDelegate alloc] init]];
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];

    NSMenu *mainMenu = [[NSMenu alloc] init];
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    [mainMenu addItem:appMenuItem];
    NSMenu *appMenu = [[NSMenu alloc] init];
    [appMenu addItemWithTitle:@"Quit Agent调度" action:@selector(terminate:) keyEquivalent:@"q"];
    [appMenuItem setSubmenu:appMenu];
    [app setMainMenu:mainMenu];

    [app activateIgnoringOtherApps:YES];
    [app run];
    return 0;
}
```

**编译**（只需一行，不需要 Xcode）：

```bash
clang -framework Cocoa -framework WebKit \
  -o "Agent调度.app/Contents/MacOS/Agent调度" \
  "Agent调度.app/Contents/MacOS/main.m" \
  -arch arm64
```

### 文件 3：`sidebar.html`

> 完整 HTML 在 `~/Desktop/Agent调度.app/Contents/Resources/sidebar.html`。
> 所有 UI 逻辑（Agent 分组、折叠、进度条动画、统计数据）全在 HTML 内的 JS 里。

**改 UI 不需要重新编译**，直接改 `sidebar.html`，重启 app 即生效。

改任务数据改 JS 里的 `TASKS` 数组：
```js
const TASKS = [
  { agent:'hermes', name:'任务名', p:88, s:'running', t:'12:00' },
  // p=进度百分比, s=done|running|queued, t=时间
];
```

---

## 启动 & 管理

```bash
# 启动
open ~/Desktop/Agent调度.app

# 关闭
pkill -f "Agent调度.app/Contents/MacOS/Agent调度"

# 查看是否在跑
pgrep -fl Agent调度
```

macOS 登录项里加一下就能开机自启。

---

## 为什么没用其他方案

| 方案 | 为什么不 |
|------|----------|
| **Electron** | 几百 MB，为个 300px 侧边栏不值得 |
| **SwiftUI** | 需要 Xcode 完整安装（用户只有 Command Line Tools） |
| **Python tkinter** | Tk 9.0 在 macOS 上 `MouseWheel` 事件不触发（Bug） |
| **JXA** | `NSObject.extend` 不存在，无法自定义 delegate |
| **Safari 弹窗** | 无独立 Dock 图标，无法最小化到程序坞 |
| **ObjC + WKWebView** | ✅ 零依赖、10KB 源码、原生滚动、Dock 图标、三色按钮 |

---

*生成时间：2026-06-12 · 失败 5 次后的收敛方案*
