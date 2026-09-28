import AppKit
import SwiftUI
import Translation

struct PromptView: View {
    let model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Circle()
                    .fill(model.state == .listening ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text("LivePrompt")
                    .font(.headline)
                Spacer()
                Text(model.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Button("停止") { Task { await model.stop() } }
                    .disabled(!model.isActive)
                    .buttonStyle(.bordered)
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(model.lines.suffix(3)) { line in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(line.english)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                            Text(line.japanese ?? "翻訳中…")
                                .font(.system(size: 22, weight: .semibold))
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !model.partialEnglish.isEmpty {
                        Text(model.partialEnglish)
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                    }
                    if model.lines.isEmpty && model.partialEnglish.isEmpty {
                        Text("英語音声が再生されると、ここに字幕が表示されます。")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)

            Divider()
            SuggestionView(model: model)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(1 - model.promptTransparency))
        }
        .translationTask(model.translationConfiguration) { session in
            await model.consumeTranslations(using: session)
        }
    }
}

struct SuggestionView: View {
    let model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("英語で話すヒント")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(model.suggestionMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if let suggestion = model.suggestion {
                suggestionRow("質問", text: suggestion.question)
                suggestionRow("返答", text: suggestion.reply)
            }
        }
    }

    private func suggestionRow(_ title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)
            Text(text)
                .font(.callout)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .help("コピー")
        }
    }
}
