import AVFoundation
import Foundation
import Observation
import Translation

private struct TranslationJob {
    let sessionID: UUID
    let lineID: UUID
    let text: String
}

@MainActor
@Observable
final class AppModel {
    private(set) var state: CaptureState = .idle
    private(set) var lines: [CaptionLine] = []
    private(set) var partialEnglish = ""
    private(set) var suggestion: EnglishSuggestion?
    private(set) var suggestionMessage = "会話が始まると英語の質問・返答案を表示します。"
    var translationConfiguration: TranslationSession.Configuration?

    @ObservationIgnored private let capture = SystemAudioCapture()
    @ObservationIgnored private let transcription = LiveTranscriptionService()
    @ObservationIgnored private let suggestionService = SuggestionService()
    @ObservationIgnored private let panel = PromptPanelController()
    @ObservationIgnored private var eventTask: Task<Void, Never>?
    @ObservationIgnored private var suggestionTask: Task<Void, Never>?
    @ObservationIgnored private var translationStream: AsyncStream<TranslationJob>?
    @ObservationIgnored private var translationBuilder: AsyncStream<TranslationJob>.Continuation?
    @ObservationIgnored private var sessionID = UUID()
    @ObservationIgnored private var transcriptRevision = 0
    @ObservationIgnored private var lastSuggestedRevision = 0
    @ObservationIgnored private var lastSuggestionAt: Date?

    var statusText: String {
        switch state {
        case .idle: "停止中"
        case .preparing: "音声・言語モデルを準備中…"
        case .listening: "Macの再生音声を聞き取り中"
        case .stopping: "停止中…"
        case .failed(let message): message
        }
    }

    var isActive: Bool {
        state == .preparing || state == .listening
    }

    func start() async {
        guard !isActive, state != .stopping else { return }
        let token = UUID()
        sessionID = token
        state = .preparing
        lines = []
        partialEnglish = ""
        suggestion = nil
        suggestionMessage = suggestionService.availabilityMessage ?? "会話が始まると英語の質問・返答案を表示します。"
        transcriptRevision = 0
        lastSuggestedRevision = 0
        lastSuggestionAt = nil

        let (stream, builder) = AsyncStream<TranslationJob>.makeStream(bufferingPolicy: .bufferingNewest(16))
        translationStream = stream
        translationBuilder = builder
        translationConfiguration = .init(
            source: Locale.Language(identifier: "en"),
            target: Locale.Language(identifier: "ja")
        )
        panel.show(model: self)

        do {
            let audio = try await capture.start { [weak self] error in
                Task { @MainActor [weak self] in
                    self?.fail(error.localizedDescription, for: token)
                }
            }
            guard sessionID == token else {
                await capture.stop()
                return
            }
            let events = try await transcription.start(audio: audio)
            guard sessionID == token else {
                await capture.stop()
                await transcription.stop()
                return
            }
            state = .listening
            eventTask = Task { [weak self] in
                for await event in events {
                    guard let self, !Task.isCancelled else { return }
                    self.handle(event, for: token)
                }
                if let self, self.sessionID == token, self.state == .listening {
                    self.fail("音声認識が終了しました。もう一度開始してください。", for: token)
                }
            }
        } catch {
            fail("開始できませんでした: \(error.localizedDescription) システムオーディオ録音の許可を確認してください。", for: token)
        }
    }

    func stop() async {
        guard state != .idle, state != .stopping else { return }
        state = .stopping
        sessionID = UUID()
        eventTask?.cancel()
        eventTask = nil
        suggestionTask?.cancel()
        suggestionTask = nil
        translationBuilder?.finish()
        translationBuilder = nil
        translationStream = nil
        translationConfiguration = nil
        await capture.stop()
        await transcription.stop()
        partialEnglish = ""
        state = .idle
        panel.hide()
    }

    func consumeTranslations(using session: TranslationSession) async {
        guard let translationStream else { return }
        for await job in translationStream {
            if Task.isCancelled { return }
            guard sessionID == job.sessionID else { continue }
            do {
                let result = try await session.translate(job.text)
                guard sessionID == job.sessionID,
                      let index = lines.firstIndex(where: { $0.id == job.lineID }) else { continue }
                lines[index].japanese = result.targetText
            } catch {
                guard sessionID == job.sessionID,
                      let index = lines.firstIndex(where: { $0.id == job.lineID }) else { continue }
                lines[index].japanese = "翻訳できませんでした: \(error.localizedDescription)"
            }
        }
    }

    private func handle(_ event: TranscriptEvent, for token: UUID) {
        guard sessionID == token, state == .listening else { return }
        switch event {
        case .partial(let text):
            partialEnglish = text
        case .final(let text):
            partialEnglish = ""
            let line = CaptionLine(english: text)
            lines.append(line)
            if lines.count > 12 { lines.removeFirst(lines.count - 12) }
            translationBuilder?.yield(TranslationJob(sessionID: token, lineID: line.id, text: text))
            transcriptRevision += 1
            scheduleSuggestions()
        case .failure(let message):
            fail("音声認識エラー: \(message)", for: token)
        }
    }

    private func scheduleSuggestions() {
        guard suggestionTask == nil,
              suggestionService.availabilityMessage == nil,
              transcriptRevision > lastSuggestedRevision else { return }
        let elapsed = lastSuggestionAt.map { Date().timeIntervalSince($0) } ?? 20
        let wait = max(0, 12 - elapsed)
        suggestionTask = Task { [weak self] in
            if wait > 0 {
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            }
            guard let self, !Task.isCancelled, self.state == .listening else { return }
            let token = self.sessionID
            let revision = self.transcriptRevision
            let context = self.lines.suffix(3).map(\.english).joined(separator: "\n").suffix(1_000)
            self.lastSuggestionAt = Date()
            self.suggestionMessage = "英語の案を作成中…"
            do {
                let result = try await self.suggestionService.generate(from: String(context))
                guard !Task.isCancelled, self.sessionID == token else { return }
                self.suggestion = result
                self.suggestionMessage = "直近の会話からの提案"
            } catch {
                guard self.sessionID == token else { return }
                self.suggestionMessage = "提案を作れませんでした: \(error.localizedDescription)"
            }
            self.lastSuggestedRevision = revision
            self.suggestionTask = nil
            if self.transcriptRevision > revision { self.scheduleSuggestions() }
        }
    }

    private func fail(_ message: String, for token: UUID) {
        guard sessionID == token, state != .stopping else { return }
        Task {
            await stop()
            state = .failed(message)
        }
    }
}
