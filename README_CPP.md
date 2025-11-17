# Objective-C++ Scroll→Right-Click Macro

This folder contains an Objective-C++ implementation `macro.mm` that listens for global scroll events and synthesizes right-clicks at the mouse pointer.

Files
- `macro.mm` – Objective-C++ source using a CoreGraphics event tap.
- `Makefile` – build helper (requires clang/clang++).

Build
```bash
cd /Users/ATM/Downloads/Vscode
make
```
This creates a `macro` executable in the same directory.

Permissions
- You must grant Accessibility and Input Monitoring to the built binary (or the Terminal if you run it from Terminal) in System Settings → Privacy & Security.

Run
```bash
./macro
```
Controls (global)
- Ctrl+Alt+R — toggle macro on/off
- Ctrl+Shift+` — toggle a soft cap (100 CPS). When enabled, the macro will not issue clicks faster than 100 clicks/sec.

Behavior
- The program accumulates scroll delta and issues right-clicks proportional to total scroll movement. Sensitivity and other parameters are defined at the top of `macro.mm`.

Notes
- This is a low-level native implementation; it will require the same accessibility permissions as Hammerspoon.
- If you want the program to run automatically at login, create a LaunchAgent plist or add it to Login Items.
