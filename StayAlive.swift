import SwiftUI
import IOKit.pwr_mgt
import ApplicationServices

// Holds an IOKit power assertion that prevents the display from sleeping, and periodically
// sends a tiny mouse nudge plus a click so apps like Teams still see the user as active.
final class Awake: ObservableObject {
    @Published private(set) var isOn = false
    @Published private(set) var needsAccessibility = false
    private var assertionID: IOPMAssertionID = 0
    private var timer: Timer?

    private let interval: TimeInterval = 60      // how often to simulate activity
    private let idleThreshold: TimeInterval = 50 // only act if the user has been idle this long

    func toggle() { isOn ? stop() : start() }

    func start() {
        guard !isOn else { return }
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Stay Alive is keeping the screen on" as CFString,
            &assertionID)
        isOn = (result == kIOReturnSuccess)
        guard isOn else { return }

        // Posting synthetic input requires the Accessibility permission.
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        needsAccessibility = !AXIsProcessTrustedWithOptions(opts)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.simulateActivity()
        }
    }

    // Nudges the mouse 1 px and back, then clicks at the cursor. Skipped while the user is active.
    private func simulateActivity() {
        needsAccessibility = !AXIsProcessTrusted()
        guard !needsAccessibility else { return }
        let anyInput = CGEventType(rawValue: ~0)!
        guard CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput) >= idleThreshold
        else { return }

        guard let pos = CGEvent(source: nil)?.location else { return }
        let src = CGEventSource(stateID: .hidSystemState)
        func post(_ type: CGEventType, _ p: CGPoint) {
            CGEvent(mouseEventSource: src, mouseType: type, mouseCursorPosition: p, mouseButton: .left)?
                .post(tap: .cghidEventTap)
        }
        post(.mouseMoved, CGPoint(x: pos.x + 1, y: pos.y))
        post(.mouseMoved, pos)
        // Never click our own window, or the click would hit the power button and switch us off.
        let overOwnWindow = NSApp.windows.contains { $0.isVisible && $0.frame.contains(NSEvent.mouseLocation) }
        guard !overOwnWindow else { return }
        post(.leftMouseDown, pos)
        post(.leftMouseUp, pos)
    }

    func stop() {
        guard isOn else { return }
        timer?.invalidate()
        timer = nil
        IOPMAssertionRelease(assertionID)
        isOn = false
        needsAccessibility = false
    }
}

struct ContentView: View {
    @EnvironmentObject var awake: Awake

    var body: some View {
        VStack(spacing: 18) {
            Button(action: awake.toggle) {
                ZStack {
                    Circle()
                        .fill(awake.isOn ? Color.green : Color.gray.opacity(0.35))
                        .shadow(color: awake.isOn ? .green.opacity(0.6) : .clear, radius: 18)
                    Image(systemName: "power")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 150, height: 150)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: awake.isOn)

            Text(awake.isOn ? "Screen stays on" : "Off — normal sleep")
                .font(.headline)
                .foregroundColor(awake.isOn ? .green : .secondary)

            if awake.needsAccessibility {
                Text("Allow Stay Alive in System Settings → Privacy & Security → Accessibility so it can click.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.orange)
            }
        }
        .padding(30)
        .frame(width: 260, height: 300)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let awake = Awake()
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) { awake.stop() }
}

@main
struct StayAliveApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup("Stay Alive") {
            ContentView().environmentObject(delegate.awake)
        }
        .windowResizability(.contentSize)
    }
}
