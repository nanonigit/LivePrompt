import AVFoundation
import Speech

enum TranscriptEvent {
    case partial(String)
    case final(String)
    case failure(String)
}

actor LiveTranscriptionService {
    private var analyzer: SpeechAnalyzer?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var audioTask: Task<Void, Never>?
    private var resultTask: Task<Void, Never>?
    private var eventBuilder: AsyncStream<TranscriptEvent>.Continuation?
    private var analyzerFormat: AVAudioFormat?
    private var converter: AVAudioConverter?

    func start(audio: AsyncStream<AVAudioPCMBuffer>) async throws -> AsyncStream<TranscriptEvent> {
        let locale = Locale(identifier: "en-US")
        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: []
        )
        let supported = await SpeechTranscriber.supportedLocales
        guard supported.contains(where: { $0.identifier(.bcp47) == locale.identifier(.bcp47) }) else {
            throw TranscriptionError.unsupportedLanguage
        }
        if let download = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await download.downloadAndInstall()
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            throw TranscriptionError.missingAudioFormat
        }
        let (inputs, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream(bufferingPolicy: .bufferingNewest(48))
        let (events, eventBuilder) = AsyncStream<TranscriptEvent>.makeStream(bufferingPolicy: .bufferingNewest(24))
        self.analyzer = analyzer
        self.analyzerFormat = format
        self.inputBuilder = inputBuilder
        self.eventBuilder = eventBuilder

        do {
            try await analyzer.start(inputSequence: inputs)
        } catch {
            inputBuilder.finish()
            eventBuilder.finish()
            self.analyzer = nil
            self.inputBuilder = nil
            self.eventBuilder = nil
            throw error
        }

        resultTask = Task {
            do {
                for try await result in transcriber.results {
                    let text = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { continue }
                    eventBuilder.yield(result.isFinal ? .final(text) : .partial(text))
                }
            } catch {
                eventBuilder.yield(.failure(error.localizedDescription))
            }
            eventBuilder.finish()
        }

        audioTask = Task {
            for await buffer in audio {
                if Task.isCancelled { break }
                do {
                    try append(buffer)
                } catch {
                    eventBuilder.yield(.failure(error.localizedDescription))
                    break
                }
            }
            inputBuilder.finish()
        }

        return events
    }

    func stop() async {
        audioTask?.cancel()
        inputBuilder?.finish()
        if let analyzer {
            try? await analyzer.finalizeAndFinishThroughEndOfInput()
        }
        resultTask?.cancel()
        eventBuilder?.finish()
        audioTask = nil
        resultTask = nil
        eventBuilder = nil
        inputBuilder = nil
        analyzer = nil
        analyzerFormat = nil
        converter = nil
    }

    private func append(_ source: AVAudioPCMBuffer) throws {
        guard let format = analyzerFormat, let inputBuilder else { return }
        if source.format.isEqual(format) {
            inputBuilder.yield(AnalyzerInput(buffer: source))
            return
        }
        if converter == nil || !converter!.inputFormat.isEqual(source.format) {
            converter = AVAudioConverter(from: source.format, to: format)
        }
        guard let converter else { throw TranscriptionError.conversionFailed }
        let ratio = format.sampleRate / source.format.sampleRate
        let capacity = AVAudioFrameCount(Double(source.frameLength) * ratio + 1024)
        guard let converted = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
            throw TranscriptionError.conversionFailed
        }
        var supplied = false
        var conversionError: NSError?
        let status = converter.convert(to: converted, error: &conversionError) { _, inputStatus in
            if supplied {
                inputStatus.pointee = .noDataNow
                return nil
            }
            supplied = true
            inputStatus.pointee = .haveData
            return source
        }
        if status == .error { throw conversionError ?? TranscriptionError.conversionFailed as NSError }
        if converted.frameLength > 0 {
            inputBuilder.yield(AnalyzerInput(buffer: converted))
        }
    }
}

private enum TranscriptionError: LocalizedError {
    case unsupportedLanguage
    case missingAudioFormat
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .unsupportedLanguage: "このMacでは英語の文字起こしモデルを利用できません。"
        case .missingAudioFormat: "文字起こし用の音声形式を決められませんでした。"
        case .conversionFailed: "再生音声を文字起こし用に変換できませんでした。"
        }
    }
}
