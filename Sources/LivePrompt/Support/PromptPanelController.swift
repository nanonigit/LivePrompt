import AppKit
import SwiftUI

@MainActor
final class PromptPanelController {
    private var panel: PromptPanel?

    func show(model: AppModel) {
        if let panel {
            panel.orderFrontRegardless()
            return
        }
        let width: CGFloat = 620
        let height: CGFloat = 390
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let frame = NSRect(
            x: screen.midX - width / 2,
            y: screen.minY + 70,
            width: width,
            height: height
        )
        let panel = PromptPanel(contentRect: frame, styleMask: [.borderless, .resizable], backing: .buffered, defer: false)
        panel.minSize = NSSize(width: 440, height: 320)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.contentView = NSHostingView(rootView: PromptView(model: model))
        panel.orderFrontRegardless()
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }
}

private final class PromptPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
