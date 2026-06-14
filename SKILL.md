---
name: macos-agent-dispatch-sidebar
description: Use when building a minimal native macOS floating sidebar app for agent or task dispatch dashboards. Provides an Objective-C + WKWebView path with Dock icon, native scrolling, editable HTML UI, and avoids tkinter, JXA, Safari popup, Electron, and SwiftUI pitfalls.
---

# macOS Agent Dispatch Sidebar

Use this skill when the user wants a small native macOS sidebar app for agent scheduling, task status, or local dashboard display.

## Preferred Path

Build a real `.app` bundle with Objective-C + WKWebView:

1. Keep the UI in `Contents/Resources/sidebar.html` so the user can edit tasks and layout without recompiling.
2. Compile `Contents/MacOS/main.m` with Command Line Tools:

```bash
clang -framework Cocoa -framework WebKit \
  -o "AgentDispatch.app/Contents/MacOS/AgentDispatch" \
  "AgentDispatch.app/Contents/MacOS/main.m" \
  -arch arm64
```

3. Launch with `open AgentDispatch.app`.
4. Verify with `pgrep -fl AgentDispatch` and by checking that the window has a Dock icon, minimize button, native scroll, and a loaded `sidebar.html`.

For the fastest deterministic build, run:

```bash
scripts/create_agent_sidebar_app.sh --out /tmp --name AgentDispatch
```

## Success Criteria

- The app bundle has `Contents/Info.plist`, `Contents/MacOS/<executable>`, and `Contents/Resources/sidebar.html`.
- The executable is a Mach-O binary compiled locally.
- The app opens as a normal macOS app, can be minimized to the Dock, and preserves native WebKit scrolling.
- UI updates only require editing `sidebar.html` and relaunching the app.

## Avoid

- Do not use tkinter for this pattern on macOS; Tk can render but mouse wheel and SDK behavior are unreliable.
- Do not use JXA for a custom WebView app; delegate/runtime behavior is fragile.
- Do not use Safari popups when the user needs an independent Dock app.
- Avoid Electron unless the user explicitly accepts the size and dependency cost.
- Avoid SwiftUI when only Command Line Tools are installed.

## References And Templates

- Read `references/from-zero-path.md` when you need the full failure history, rationale, or original Chinese walkthrough.
- Use `templates/Info.plist`, `templates/main.m`, and `templates/sidebar.html` as the minimal working app source.
