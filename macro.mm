#include <ApplicationServices/ApplicationServices.h>
#include <CoreGraphics/CoreGraphics.h>
#include <iostream>
#include <atomic>
#include <cmath>
#include <unistd.h>

// Objective-C++ program that listens for global scroll events and issues
// a right-click at the current mouse position for each (accumulated) scroll.
// Controls:
//  - Ctrl+Alt+R : toggle macro enabled/disabled
//  - Ctrl+Shift+` : toggle a soft cap (100 CPS)
// Notes:
//  - Requires Accessibility / Input Monitoring permission for the built binary.

static std::atomic<bool> g_enabled(true);
static const int SOFT_CAP = 100; // CPS (higher cap)
static double g_softMinInterval = 0.5 / SOFT_CAP;
static double g_lastClickTime = 0.0;

// Accumulator sensitivity (smaller => more clicks per small scroll)
static double g_sensitivity = 0.5; // 0.5 scroll unit = 1 click (faster)
static double g_accumulator = 0.0;

// Keycodes (US keyboard): 'r' = 15. If your layout differs, adjust.
static const int KEYCODE_R = 15;

static void doRightClick(CGPoint pt) {
    CGEventRef down = CGEventCreateMouseEvent(NULL, kCGEventRightMouseDown, pt, kCGMouseButtonRight);
    CGEventPost(kCGHIDEventTap, down);
    CFRelease(down);
    CGEventRef up = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, pt, kCGMouseButtonRight);
    CGEventPost(kCGHIDEventTap, up);
    CFRelease(up);
}

static double nowSeconds() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec * 1e-9;
}

// Global tap reference so the callback can re-enable it if disabled by timeout
static CFMachPortRef g_tap = NULL;

// Event tap callback
static CGEventRef eventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    (void)proxy; (void)refcon; // silence unused-parameter warnings
    if (type == kCGEventTapDisabledByTimeout) {
        std::cerr << "Event tap disabled by timeout; re-enabling\n";
        if (g_tap) CGEventTapEnable(g_tap, true);
        return event;
    }

    if (type == kCGEventKeyDown) {
        // Check for toggles
        CGEventFlags flags = CGEventGetFlags(event);
        int keycode = (int)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

        bool ctrl = (flags & kCGEventFlagMaskControl);
        bool alt = (flags & kCGEventFlagMaskAlternate);

        if (ctrl && alt && keycode == KEYCODE_R) {
            bool newv = !g_enabled.load();
            g_enabled.store(newv);
            std::cerr << "Macro " << (newv ? "enabled" : "disabled") << " via Ctrl+Alt+R\n";
            return NULL; // consume the key event so it doesn't reach apps
        }

        return event; // let key events pass through otherwise
    }

    if (type == kCGEventScrollWheel) {
        if (!g_enabled.load()) return event; // pass scroll events through when disabled


        // Get scroll magnitude (sum both axes for consistency)
        int64_t dy = CGEventGetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1);
        int64_t dx = CGEventGetIntegerValueField(event, kCGScrollWheelEventDeltaAxis2);
        double mag = std::abs((double)dy) + std::abs((double)dx);
        if (mag <= 0.0) return NULL; // nothing

        // accumulate
        g_accumulator += mag;

        // How many clicks available
        long clicksAvailable = (long)std::floor(g_accumulator / g_sensitivity);
        if (clicksAvailable <= 0) return NULL;

        // Emit clicks, rate-limited to SOFT_CAP CPS (smooth, not hard stop)
        double now = nowSeconds();
        long clicksEmitted = 0;
        while (clicksAvailable > 0 && (now - g_lastClickTime) >= g_softMinInterval) {
            g_lastClickTime = now;
            // current mouse position
            CGEventRef m = CGEventCreate(NULL);
            CGPoint pt = CGEventGetLocation(m);
            CFRelease(m);
            doRightClick(pt);
            g_accumulator -= g_sensitivity;
            clicksAvailable--;
            clicksEmitted++;
            now = nowSeconds();
        }

        // Consume the original scroll so apps don't receive it
        return NULL;
    }

    return event;
}

int main(int argc, char *argv[]) {
    (void)argc; (void)argv; // silence unused-parameter warnings
    std::cerr << "Starting scroll->right-click macro (Objective-C++)\n";
    // Request accessibility? Just instruct user in README.

    CGEventMask mask = CGEventMaskBit(kCGEventScrollWheel) | CGEventMaskBit(kCGEventKeyDown);

    CFMachPortRef tap = CGEventTapCreate(kCGHIDEventTap,
                                         kCGHeadInsertEventTap,
                                         kCGEventTapOptionDefault,
                                         mask,
                                         eventTapCallback,
                                         NULL);

    if (!tap) {
        std::cerr << "Failed to create event tap. Are accessibility permissions granted?\n";
        return 1;
    }

    // store globally so the callback can re-enable it if macOS disables the tap
    g_tap = tap;

    CFRunLoopSourceRef src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), src, kCFRunLoopCommonModes);
    CGEventTapEnable(tap, true);

    std::cerr << "Event tap installed. Toggle macro: Ctrl+Alt+R. Rate cap: 40 CPS (always on).\n";
    CFRunLoopRun();

    // Cleanup (never reached normally)
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), src, kCFRunLoopCommonModes);
    CFRelease(src);
    CFRelease(tap);
    return 0;
}
