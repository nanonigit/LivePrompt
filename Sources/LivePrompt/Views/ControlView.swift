import AppKit
import ServiceManagement
import SwiftUI

struct ControlView: View {
    @Environment(\.scenePhase) private var scenePhase
    let model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("LivePrompt")
                        .font(.largeTitle.bold())
                    Text("Macの英語音声を日本語字幕に。次に話す英語も提案します。")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label(model.statusText, systemImage: model.state == .listening ? "waveform" : "pause.circle")
                        .font(.subheadline)
                    Spacer()
                    if model.isActive {
                        Button("停止") { Task { await model.stop() } }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button("開始") { Task { await model.start() } }
                            .buttonStyle(.borderedProminent)
                    }
                }

                if case .failed = model.state {
                    HStack {
                        Text("システム設定 → プライバシーとセキュリティ → 画面収録とシステムオーディオ録音 → システムオーディオ録音")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("設定を開く") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                }

                Divider()

                Text("直近の字幕")
                    .font(.headline)
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(model.lines.suffix(5)) { line in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(line.english).foregroundStyle(.secondary)
                                Text(line.japanese ?? "翻訳中…")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if model.lines.isEmpty {
                            Text("開始後、Macで英語音声を再生してください。")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 130)

                Divider()
                SuggestionView(model: model)

                GroupBox("表示と起動") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("プロンプターの透明度")
                            Slider(
                                value: Binding(
                                    get: { model.promptTransparency },
                                    set: { model.promptTransparency = $0 }
                                ),
                                in: 0...0.8,
                                step: 0.05
                            )
                            Text("\(Int((model.promptTransparency * 100).rounded()))%")
                                .monospacedDigit()
                                .frame(width: 42, alignment: .trailing)
                        }
                        Toggle("ログイン時に起動", isOn: Binding(
                            get: { model.loginItemStatus == .enabled || model.loginItemStatus == .requiresApproval },
                            set: { model.setLaunchAtLogin($0) }
                        ))
                        Toggle("メニューバーにアイコンを表示", isOn: Binding(
                            get: { model.showMenuBarIcon },
                            set: { model.setMenuBarIconVisible($0) }
                        ))
                        .disabled(model.showMenuBarIcon && !model.showDockIcon)
                        Toggle("Dockにアイコンを表示", isOn: Binding(
                            get: { model.showDockIcon },
                            set: { model.setDockIconVisible($0) }
                        ))
                        .disabled(model.showDockIcon && !model.showMenuBarIcon)
                        Text("操作画面を開けるよう、メニューバーとDockのどちらか一方は表示します。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let displaySettingError = model.displaySettingError {
                            Text(displaySettingError)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        if model.loginItemStatus == .requiresApproval {
                            HStack {
                                Text("macOSの承認が必要です。")
                                Button("ログイン項目の設定を開く") {
                                    SMAppService.openSystemSettingsLoginItems()
                                }
                            }
                            .font(.caption)
                        }
                        if let loginItemError = model.loginItemError {
                            Text(loginItemError)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("使用履歴（過去30日）") {
                    VStack(alignment: .leading, spacing: 8) {
                        if model.usageSessions.isEmpty {
                            Text("まだ収録の履歴はありません。")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(model.usageSessions) { session in
                                HStack(alignment: .firstTextBaseline) {
                                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                    Spacer()
                                    if let endedAt = session.endedAt {
                                        Text("終了 \(endedAt.formatted(date: .omitted, time: .shortened))")
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("終了記録なし")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .font(.caption)
                            }
                        }
                        Text("開始・終了日時のみ保存します。音声や会話内容は保存しません。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("初回はシステム音声の収録許可と言語モデルのダウンロードが必要です。音声と会話内容は保存しません。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            model.refreshLoginItemStatus()
            model.refreshUsageSessions()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.refreshLoginItemStatus()
                model.refreshUsageSessions()
            }
        }
    }
}
