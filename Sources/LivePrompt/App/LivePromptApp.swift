import AppKit
import SwiftUI

@main
struct LivePromptApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let model = AppModel()

    var body: some Scene {
        Window("LivePrompt", id: "controls") {
            ControlView(model: model)
                .frame(minWidth: 520, minHeight: 460)
        }
        .defaultSize(width: 680, height: 560)
        .windowResizability(.contentMinSize)

        MenuBarExtra("LivePrompt", systemImage: "captions.bubble", isInserted: Binding(
            get: { model.showMenuBarIcon },
            set: { model.setMenuBarIconVisible($0) }
        )) {
            MenuBarControls(model: model)
        }
    }
}

private struct MenuBarControls: View {
    @Environment(\.openWindow) private var openWindow
    let model: AppModel

    var body: some View {
        Text(model.statusText)
        Divider()
        Button("操作画面を表示") {
            openWindow(id: "controls")
            NSApp.activate(ignoringOtherApps: true)
        }
        Button(model.isActive ? "収録を停止" : "収録を開始") {
            Task {
                if model.isActive {
                    await model.stop()
                } else {
                    await model.start()
                }
            }
        }
        .disabled(model.state == .stopping)
        Divider()
        Button("LivePromptを終了") {
            NSApp.terminate(nil)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let launchDate = Date()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let showDock = UserDefaults.standard.object(forKey: "showDockIcon") as? Bool ?? true
        NSApp.setActivationPolicy(showDock ? .regular : .accessory)
        if showDock { NSApp.activate(ignoringOtherApps: true) }
    }

    func applicationWillTerminate(_ notification: Notification) {
        UsageHistoryStore().endOpenSessions(startedAfter: launchDate)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag, let window = sender.windows.first(where: { $0.title == "LivePrompt" }) {
            window.makeKeyAndOrderFront(nil)
        }
        return true
    }
}
