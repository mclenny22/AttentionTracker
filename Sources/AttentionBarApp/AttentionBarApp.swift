import AppKit
import AttentionBarKit
import SwiftUI

@main
struct AttentionBarApplication: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var trackingEngine = TrackingEngine()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(engine: trackingEngine)
        } label: {
            MenuBarLabel(category: trackingEngine.currentCategory)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

private struct MenuBarLabel: View {
    let category: AttentionCategory?

    var body: some View {
        Image(systemName: category?.menuBarSymbol ?? "scope")
            .font(.system(size: 14, weight: .semibold))
            .help(category?.displayName ?? "Attention")
    }
}
