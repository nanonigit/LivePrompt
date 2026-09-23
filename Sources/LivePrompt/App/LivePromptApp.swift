import AppKit
import SwiftUI

@main
struct LivePromptApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let model = AppModel()

    var body: some Scene {
        WindowGroup("LivePrompt", id: "controls") {
            ControlView(model: model)
                .frame(minWidth: 520, minHeight: 460)
        }
        .defaultSize(width: 680, height: 560)
        .windowResizability(.contentMinSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
