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

        MenuBarExtra("LivePrompt", systemImage: "captions.bubble") {
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
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
