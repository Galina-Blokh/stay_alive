import SwiftUI
import IOKit.pwr_mgt

// Holds an IOKit power assertion that prevents the display from sleeping.
final class Awake: ObservableObject {
    @Published private(set) var isOn = false
    private var assertionID: IOPMAssertionID = 0

    func toggle() { isOn ? stop() : start() }

    func start() {
        guard !isOn else { return }
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Stay Alive is keeping the screen on" as CFString,
            &assertionID)
        isOn = (result == kIOReturnSuccess)
    }

    func stop() {
        guard isOn else { return }
        IOPMAssertionRelease(assertionID)
        isOn = false
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
        }
        .padding(30)
        .frame(width: 260, height: 260)
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
