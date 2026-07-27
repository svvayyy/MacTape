import CoreGraphics
import Foundation
import Testing
@testable import MacTape

@Suite("MacTape foundations")
struct MacTapeTests {
    @Test("Recording filenames are stable and readable")
    func recordingFileName() {
        let date = Date(timeIntervalSince1970: 1_767_268_923)
        let timeZone = TimeZone(secondsFromGMT: 0)!

        #expect(
            RecordingFileNamer.fileName(for: date, timeZone: timeZone)
                == "MacTape 2026-01-01 at 12.02.03.mp4"
        )
    }

    @Test("Recording filenames avoid collisions")
    func recordingFileCollision() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let date = Date(timeIntervalSince1970: 1_767_268_923)
        let initialURL = directory.appendingPathComponent(
            RecordingFileNamer.fileName(for: date)
        )
        FileManager.default.createFile(atPath: initialURL.path, contents: Data())

        let availableURL = RecordingFileNamer.availableURL(in: directory, date: date)

        #expect(availableURL.lastPathComponent.hasSuffix(" 2.mp4"))
    }

    @Test("Short recording durations use minutes and seconds")
    func shortDuration() {
        #expect(RecordingDurationFormatter.string(for: 65.9) == "01:05")
    }

    @Test("Long recording durations include hours")
    func longDuration() {
        #expect(RecordingDurationFormatter.string(for: 3_661.2) == "1:01:01")
    }

    @Test("Negative durations clamp to zero")
    func negativeDuration() {
        #expect(RecordingDurationFormatter.string(for: -14) == "00:00")
    }

    @Test("Capture dimensions preserve a normal source")
    func normalCaptureDimensions() {
        let size = CaptureDimensions.fittedPixelSize(
            for: CGSize(width: 2_560, height: 1_440)
        )

        #expect(size == CGSize(width: 2_560, height: 1_440))
    }

    @Test("Capture dimensions fit oversized sources")
    func fittedCaptureDimensions() {
        let size = CaptureDimensions.fittedPixelSize(
            for: CGSize(width: 12_032, height: 6_016)
        )

        #expect(size == CGSize(width: 6_016, height: 3_008))
    }

    @Test("Capture dimensions are even")
    func evenCaptureDimensions() {
        let size = CaptureDimensions.fittedPixelSize(
            for: CGSize(width: 1_919, height: 1_079)
        )

        #expect(Int(size.width).isMultiple(of: 2))
        #expect(Int(size.height).isMultiple(of: 2))
    }

    @Test("Only active recording is recording")
    func recordingStateSemantics() {
        #expect(RecordingState.recording.isRecording)
        #expect(!RecordingState.preparing.isRecording)
        #expect(!RecordingState.stopping.isRecording)
        #expect(!RecordingState.idle.isRecording)
    }

    @Test("ScreenCaptureKit can confirm access after a false preflight result")
    @MainActor
    func screenAccessFalseNegativeRecovery() async {
        let preferences = UserDefaults(suiteName: UUID().uuidString)!
        let model = MacTapeAppModel(
            preferences: preferences,
            screenAccessPreflight: { false },
            screenAccessRequest: { false },
            captureCatalogLoader: {
                CaptureCatalog.Snapshot(targets: [], currentApplication: nil)
            }
        )

        await model.refreshTargets()

        #expect(model.screenPermissionGranted)
        #expect(model.recordingState == .idle)
    }

    @Test("Denied screen access remains a setup state")
    @MainActor
    func deniedScreenAccess() async {
        let preferences = UserDefaults(suiteName: UUID().uuidString)!
        let model = MacTapeAppModel(
            preferences: preferences,
            screenAccessPreflight: { false },
            screenAccessRequest: { false },
            captureCatalogLoader: {
                throw TestFailure()
            }
        )

        await model.refreshTargets()

        #expect(!model.screenPermissionGranted)
        #expect(model.recordingState == .idle)
    }
}

private struct TestFailure: Error {}
