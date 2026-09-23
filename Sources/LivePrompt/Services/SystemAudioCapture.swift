import AVFoundation
import CoreAudio

actor SystemAudioCapture {
    private var tapID = AudioObjectID(kAudioObjectUnknown)
    private var deviceID = AudioObjectID(kAudioObjectUnknown)
    private var ioProcID: AudioDeviceIOProcID?
    private var continuation: AsyncStream<AVAudioPCMBuffer>.Continuation?
    private var generation = UUID()

    func start(onError: @escaping @Sendable (Error) -> Void) async throws -> AsyncStream<AVAudioPCMBuffer> {
        let token = UUID()
        generation = token
        let (samples, continuation) = AsyncStream<AVAudioPCMBuffer>.makeStream(bufferingPolicy: .bufferingNewest(48))
        do {
            let description = CATapDescription(monoGlobalTapButExcludeProcesses: [])
            description.name = "LivePrompt System Audio"
            description.isPrivate = true
            description.bundleIDs = [Bundle.main.bundleIdentifier ?? "com.naoki.liveprompt"]
            try check(AudioHardwareCreateProcessTap(description, &tapID), "音声タップの作成")

            var unmanagedUID: Unmanaged<CFString>?
            var uidSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
            var uidAddress = AudioObjectPropertyAddress(
                mSelector: kAudioTapPropertyUID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            let uidStatus = withUnsafeMutablePointer(to: &unmanagedUID) { pointer in
                AudioObjectGetPropertyData(tapID, &uidAddress, 0, nil, &uidSize, pointer)
            }
            try check(uidStatus, "音声タップの識別")
            guard let uid = unmanagedUID?.takeRetainedValue() else { throw CaptureError.missingTapUID }

            let deviceDescription: [String: Any] = [
                kAudioAggregateDeviceNameKey: "LivePrompt Audio",
                kAudioAggregateDeviceUIDKey: "com.naoki.liveprompt.\(UUID().uuidString)",
                kAudioAggregateDeviceIsPrivateKey: true,
                kAudioAggregateDeviceTapListKey: [[kAudioSubTapUIDKey: uid]],
                kAudioAggregateDeviceTapAutoStartKey: true
            ]
            try check(AudioHardwareCreateAggregateDevice(deviceDescription as CFDictionary, &deviceID), "音声デバイスの作成")
            try await waitUntilDeviceIsAlive(for: token)

            var streamDescription = AudioStreamBasicDescription()
            var formatSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
            var formatAddress = AudioObjectPropertyAddress(
                mSelector: kAudioTapPropertyFormat,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            try check(AudioObjectGetPropertyData(tapID, &formatAddress, 0, nil, &formatSize, &streamDescription), "音声形式の取得")
            guard let format = AVAudioFormat(streamDescription: &streamDescription) else {
                throw CaptureError.unsupportedFormat
            }

            let queue = DispatchQueue(label: "LivePrompt.systemAudio", qos: .userInitiated)
            try check(AudioDeviceCreateIOProcIDWithBlock(&ioProcID, deviceID, queue) { _, input, _, _, _ in
                do {
                    try Self.copy(input, format: format, to: continuation)
                } catch {
                    onError(error)
                }
            }, "音声コールバックの登録")
            try check(AudioDeviceStart(deviceID, ioProcID), "システム音声の収録開始")
            self.continuation = continuation
            return samples
        } catch {
            continuation.finish()
            if generation == token { releaseAudioObjects() }
            throw error
        }
    }

    func stop() async {
        generation = UUID()
        continuation?.finish()
        continuation = nil
        releaseAudioObjects()
    }

    private func releaseAudioObjects() {
        if let ioProcID, deviceID != kAudioObjectUnknown {
            AudioDeviceStop(deviceID, ioProcID)
            AudioDeviceDestroyIOProcID(deviceID, ioProcID)
        }
        ioProcID = nil
        if deviceID != kAudioObjectUnknown {
            AudioHardwareDestroyAggregateDevice(deviceID)
            deviceID = kAudioObjectUnknown
        }
        if tapID != kAudioObjectUnknown {
            AudioHardwareDestroyProcessTap(tapID)
            tapID = kAudioObjectUnknown
        }
    }

    nonisolated private static func copy(
        _ input: UnsafePointer<AudioBufferList>,
        format: AVAudioFormat,
        to continuation: AsyncStream<AVAudioPCMBuffer>.Continuation
    ) throws {
        let buffers = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input))
        guard let first = buffers.first, first.mDataByteSize > 0 else { return }
        let bytesPerFrame = Int(format.streamDescription.pointee.mBytesPerFrame)
        guard bytesPerFrame > 0 else { throw CaptureError.unsupportedFormat }
        let frames = AVAudioFrameCount(Int(first.mDataByteSize) / bytesPerFrame)
        guard frames > 0, let copy = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
        copy.frameLength = frames
        let destination = UnsafeMutableAudioBufferListPointer(copy.mutableAudioBufferList)
        guard buffers.count == destination.count else { throw CaptureError.unsupportedFormat }
        for index in buffers.indices {
            guard let source = buffers[index].mData, let target = destination[index].mData else { continue }
            memcpy(target, source, min(Int(buffers[index].mDataByteSize), Int(destination[index].mDataByteSize)))
        }
        continuation.yield(copy)
    }

    private func check(_ status: OSStatus, _ operation: String) throws {
        guard status == noErr else { throw CaptureError.system(operation, status) }
    }

    private func waitUntilDeviceIsAlive(for token: UUID) async throws {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsAlive,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        for _ in 0..<30 {
            guard generation == token else { throw CancellationError() }
            var isAlive: UInt32 = 0
            var size = UInt32(MemoryLayout<UInt32>.size)
            let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &isAlive)
            if status == noErr && isAlive != 0 { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw CaptureError.deviceNotReady
    }
}

private enum CaptureError: LocalizedError {
    case unsupportedFormat
    case missingTapUID
    case deviceNotReady
    case system(String, OSStatus)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            "Macのシステム音声形式を読み取れませんでした。"
        case .missingTapUID:
            "システム音声タップを識別できませんでした。"
        case .deviceNotReady:
            "システム音声デバイスの準備が完了しませんでした。"
        case .system(let operation, let status):
            "\(operation)に失敗しました (Core Audio: \(status))。"
        }
    }
}
