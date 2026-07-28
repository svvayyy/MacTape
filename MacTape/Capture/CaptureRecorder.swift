@preconcurrency import AVFoundation
@preconcurrency import ScreenCaptureKit

@MainActor
final class CaptureRecorder: NSObject {
    var onFailure: ((Error) -> Void)?

    private var stream: SCStream?
    private var recordingOutput: SCRecordingOutput?
    private var outputURL: URL?
    private var stopContinuation: CheckedContinuation<URL, Error>?
    private var hasFinished = false

    func start(
        target: CaptureTarget,
        excluding application: SCRunningApplication?,
        systemAudio: Bool,
        microphone: Bool,
        resolution: CaptureResolution,
        outputURL: URL
    ) async throws {
        let contentFilter = target.contentFilter(excluding: application)
        let sourceSize = CaptureDimensions.sourcePixelSize(
            contentRect: contentFilter.contentRect,
            pointPixelScale: CGFloat(contentFilter.pointPixelScale)
        )
        let dimensions = CaptureDimensions.fittedPixelSize(
            for: sourceSize,
            resolution: resolution
        )
        let streamConfiguration = SCStreamConfiguration()
        streamConfiguration.width = Int(dimensions.width)
        streamConfiguration.height = Int(dimensions.height)
        streamConfiguration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        streamConfiguration.queueDepth = 6
        streamConfiguration.showsCursor = true
        streamConfiguration.capturesAudio = systemAudio
        streamConfiguration.captureMicrophone = microphone
        streamConfiguration.excludesCurrentProcessAudio = true
        streamConfiguration.sampleRate = 48_000
        streamConfiguration.channelCount = 2

        let outputConfiguration = SCRecordingOutputConfiguration()
        outputConfiguration.outputURL = outputURL
        outputConfiguration.videoCodecType = .h264
        outputConfiguration.outputFileType = .mp4

        let recordingOutput = SCRecordingOutput(
            configuration: outputConfiguration,
            delegate: self
        )
        let stream = SCStream(
            filter: contentFilter,
            configuration: streamConfiguration,
            delegate: self
        )

        try stream.addRecordingOutput(recordingOutput)

        self.outputURL = outputURL
        self.recordingOutput = recordingOutput
        self.stream = stream
        hasFinished = false

        do {
            try await stream.startCapture()
        } catch {
            clear()
            throw error
        }
    }

    func stop() async throws -> URL {
        guard let stream, let outputURL else {
            throw MacTapeCaptureError.notRecording
        }

        if hasFinished {
            clear()
            return outputURL
        }

        return try await withCheckedThrowingContinuation { continuation in
            stopContinuation = continuation

            Task {
                do {
                    try await stream.stopCapture()
                } catch {
                    finish(with: .failure(error))
                }
            }
        }
    }

    private func finish(with result: Result<URL, Error>) {
        guard !hasFinished else {
            return
        }

        hasFinished = true
        stopContinuation?.resume(with: result)
        stopContinuation = nil
        clear()
    }

    private func clear() {
        stream = nil
        recordingOutput = nil
        outputURL = nil
    }
}

extension CaptureRecorder: SCRecordingOutputDelegate {
    nonisolated func recordingOutputDidFinishRecording(_ recordingOutput: SCRecordingOutput) {
        Task { @MainActor [weak self] in
            guard let self, let outputURL = self.outputURL else {
                return
            }

            self.finish(with: .success(outputURL))
        }
    }

    nonisolated func recordingOutput(
        _ recordingOutput: SCRecordingOutput,
        didFailWithError error: any Error
    ) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            if self.stopContinuation != nil {
                self.finish(with: .failure(error))
            } else {
                self.onFailure?(error)
                self.clear()
            }
        }
    }
}

extension CaptureRecorder: SCStreamDelegate {
    nonisolated func stream(_ stream: SCStream, didStopWithError error: any Error) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            if self.stopContinuation != nil {
                self.finish(with: .failure(error))
            } else {
                self.onFailure?(error)
                self.clear()
            }
        }
    }
}

enum MacTapeCaptureError: LocalizedError {
    case notRecording
    case noRecordingSegments
    case noVideoTrack
    case finalizationFailed
    case screenshotEncodingFailed

    var errorDescription: String? {
        switch self {
        case .notRecording:
            "There is no active recording to stop."
        case .noRecordingSegments:
            "The recording did not contain any completed segments."
        case .noVideoTrack:
            "A recording segment did not contain video."
        case .finalizationFailed:
            "MacTape could not create the final MP4."
        case .screenshotEncodingFailed:
            "MacTape could not create the screenshot."
        }
    }
}
