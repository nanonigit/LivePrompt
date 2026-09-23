import AppKit
import SwiftUI

struct ControlView: View {
    let model: AppModel

    var body: some View {
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
            .frame(maxHeight: .infinity)

            Divider()
            SuggestionView(model: model)

            Text("初回はシステム音声の収録許可と言語モデルのダウンロードが必要です。音声と会話内容は保存しません。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
