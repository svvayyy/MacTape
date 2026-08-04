import AVFoundation
import CoreGraphics
import Foundation
import Testing
@testable import ClipTape

@Suite("ClipTape foundations")
struct ClipTapeTests {
    @Test("Recording filenames are stable and readable")
    func recordingFileName() {
        let date = Date(timeIntervalSince1970: 1_767_268_923)
        let timeZone = TimeZone(secondsFromGMT: 0)!

        #expect(
            RecordingFileNamer.fileName(for: date, timeZone: timeZone)
                == "ClipTape 2026-01-01 at 12.02.03.mp4"
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

    @Test("Retina capture dimensions use physical pixels")
    func retinaCaptureDimensions() {
        let size = CaptureDimensions.sourcePixelSize(
            contentRect: CGRect(x: 0, y: 0, width: 1_920, height: 1_080),
            pointPixelScale: 2
        )

        #expect(size == CGSize(width: 3_840, height: 2_160))
    }

    @Test("4K output uses Retina source resolution")
    func ultraHDRetinaDimensions() {
        let sourceSize = CaptureDimensions.sourcePixelSize(
            contentRect: CGRect(x: 0, y: 0, width: 2_560, height: 1_440),
            pointPixelScale: 2
        )
        let outputSize = CaptureDimensions.fittedPixelSize(
            for: sourceSize,
            resolution: .ultraHD
        )

        #expect(outputSize == CGSize(width: 3_840, height: 2_160))
    }

    @Test("1080p output fits a larger landscape source")
    func fullHDLandscapeDimensions() {
        let size = CaptureDimensions.fittedPixelSize(
            for: CGSize(width: 2_560, height: 1_440),
            resolution: .fullHD
        )

        #expect(size == CGSize(width: 1_920, height: 1_080))
    }

    @Test("1440p output fits a larger landscape source")
    func quadHDLandscapeDimensions() {
        let size = CaptureDimensions.fittedPixelSize(
            for: CGSize(width: 3_840, height: 2_160),
            resolution: .quadHD
        )

        #expect(size == CGSize(width: 2_560, height: 1_440))
    }

    @Test("1440p output respects portrait orientation")
    func quadHDPortraitDimensions() {
        let size = CaptureDimensions.fittedPixelSize(
            for: CGSize(width: 2_160, height: 3_840),
            resolution: .quadHD
        )

        #expect(size == CGSize(width: 1_440, height: 2_560))
    }

    @Test("1080p output respects portrait orientation")
    func fullHDPortraitDimensions() {
        let size = CaptureDimensions.fittedPixelSize(
            for: CGSize(width: 1_440, height: 2_560),
            resolution: .fullHD
        )

        #expect(size == CGSize(width: 1_080, height: 1_920))
    }

    @Test("Output resolution never upscales a smaller source")
    func outputResolutionDoesNotUpscale() {
        let size = CaptureDimensions.fittedPixelSize(
            for: CGSize(width: 1_280, height: 720),
            resolution: .ultraHD
        )

        #expect(size == CGSize(width: 1_280, height: 720))
    }

    @Test("Only active recording is recording")
    func recordingStateSemantics() {
        #expect(RecordingState.recording.isRecording)
        #expect(RecordingState.paused.isPaused)
        #expect(RecordingState.paused.hasActiveSession)
        #expect(RecordingState.pausing.hasActiveSession)
        #expect(RecordingState.resuming.hasActiveSession)
        #expect(!RecordingState.preparing.isRecording)
        #expect(!RecordingState.stopping.isRecording)
        #expect(!RecordingState.idle.isRecording)
    }

    @Test("Screenshot filenames are stable and readable")
    func screenshotFileName() {
        let date = Date(timeIntervalSince1970: 1_767_268_923)
        let timeZone = TimeZone(secondsFromGMT: 0)!

        #expect(
            ScreenshotFileNamer.fileName(for: date, timeZone: timeZone)
                == "ClipTape 2026-01-01 at 12.02.03.png"
        )
    }

    @Test("Selected save folders survive bookmark restoration")
    func selectedSaveFolderBookmark() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let selectedAccess = try PersistentDirectoryAccess(
            selectedURL: directory
        )
        let restoredAccess = try PersistentDirectoryAccess(
            bookmarkData: selectedAccess.bookmarkData
        )

        #expect(
            restoredAccess.url.standardizedFileURL
                == directory.standardizedFileURL
        )
    }

    @Test("A new install does not preset a save folder")
    @MainActor
    func newInstallRequiresFolderSelection() {
        let suiteName = UUID().uuidString
        let preferences = UserDefaults(suiteName: suiteName)!
        defer {
            preferences.removePersistentDomain(forName: suiteName)
        }

        let model = ClipTapeAppModel(
            preferences: preferences,
            screenAccessPreflight: { false },
            screenAccessRequest: { false },
            captureCatalogLoader: {
                CaptureCatalog.Snapshot(targets: [], currentApplication: nil)
            }
        )

        #expect(model.saveDirectory == nil)
        #expect(model.saveDirectoryLabel == "Choose Folder…")
    }

    @Test("A one-segment session finalizes without transcoding")
    func oneSegmentFinalization() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        var session = try RecordingSessionFiles.create(in: directory)
        let segmentURL = session.nextSegmentURL()
        let expectedData = Data("cliptape".utf8)
        try expectedData.write(to: segmentURL)
        session.appendSegment(segmentURL)

        let outputURL = try await RecordingSegmentFinalizer.finalize(session)

        #expect(outputURL == session.finalURL)
        #expect(try Data(contentsOf: outputURL) == expectedData)
        #expect(!FileManager.default.fileExists(atPath: session.workingDirectory.path))
    }

    @Test("Discard removes temporary recording files")
    func recordingSessionDiscard() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        var session = try RecordingSessionFiles.create(in: directory)
        let segmentURL = session.nextSegmentURL()
        try Data("temporary".utf8).write(to: segmentURL)
        session.appendSegment(segmentURL)
        session.discard()

        #expect(!FileManager.default.fileExists(atPath: session.workingDirectory.path))
        #expect(!FileManager.default.fileExists(atPath: session.finalURL.path))
    }

    @Test("Paused segments join into one playable MP4")
    func pausedSegmentFinalization() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        var session = try RecordingSessionFiles.create(in: directory)

        for _ in 0..<2 {
            let segmentURL = session.nextSegmentURL()
            try await TestVideoFactory.createSegment(at: segmentURL)
            session.appendSegment(segmentURL)
        }

        let outputURL = try await RecordingSegmentFinalizer.finalize(session)
        let asset = AVURLAsset(url: outputURL)
        let duration = try await asset.load(.duration)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)

        #expect(duration.seconds > 3.9)
        #expect(duration.seconds < 4.1)
        #expect(videoTracks.count == 1)
    }

    @Test("Passive preparation never opens protected capture content without access")
    @MainActor
    func passivePreparationDoesNotPrompt() async {
        let preferences = UserDefaults(suiteName: UUID().uuidString)!
        var loadCount = 0
        let model = ClipTapeAppModel(
            preferences: preferences,
            screenAccessPreflight: { false },
            screenAccessRequest: { false },
            captureCatalogLoader: {
                loadCount += 1
                return CaptureCatalog.Snapshot(targets: [], currentApplication: nil)
            }
        )

        await model.prepare()
        await model.prepare()

        #expect(loadCount == 0)
        #expect(!model.screenPermissionGranted)
        #expect(model.recordingState == .idle)
    }

    @Test("Denied screen access remains a setup state")
    @MainActor
    func deniedScreenAccess() async {
        let preferences = UserDefaults(suiteName: UUID().uuidString)!
        let model = ClipTapeAppModel(
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

    @Test("Confirmed screen access never requests permission again")
    @MainActor
    func confirmedScreenAccessDoesNotRequestAgain() async {
        let preferences = UserDefaults(suiteName: UUID().uuidString)!
        var requestCount = 0
        let model = ClipTapeAppModel(
            preferences: preferences,
            screenAccessPreflight: { true },
            screenAccessRequest: {
                requestCount += 1
                return true
            },
            captureCatalogLoader: {
                CaptureCatalog.Snapshot(targets: [], currentApplication: nil)
            }
        )

        await model.refreshTargets(requestPermission: true)

        #expect(requestCount == 0)
        #expect(model.screenPermissionGranted)
    }

    @Test("Passive refresh failure preserves confirmed screen access")
    @MainActor
    func passiveRefreshFailurePreservesAccess() async {
        let preferences = UserDefaults(suiteName: UUID().uuidString)!
        var hasAccess = true
        var loadCount = 0
        let model = ClipTapeAppModel(
            preferences: preferences,
            screenAccessPreflight: { hasAccess },
            screenAccessRequest: { false },
            captureCatalogLoader: {
                loadCount += 1

                if loadCount == 1 {
                    return CaptureCatalog.Snapshot(targets: [], currentApplication: nil)
                }

                throw TestFailure()
            }
        )

        await model.refreshTargets()
        hasAccess = false
        await model.refreshTargets()

        #expect(model.screenPermissionGranted)
        #expect(model.recordingState == .idle)
    }

    @Test("Returning from settings refreshes only after access is confirmed")
    @MainActor
    func settingsReturnRefreshesAfterAccess() async {
        let preferences = UserDefaults(suiteName: UUID().uuidString)!
        var hasAccess = false
        var loadCount = 0
        let model = ClipTapeAppModel(
            preferences: preferences,
            screenAccessPreflight: { hasAccess },
            screenAccessRequest: { false },
            captureCatalogLoader: {
                loadCount += 1
                return CaptureCatalog.Snapshot(targets: [], currentApplication: nil)
            }
        )

        await model.refreshTargets(requestPermission: true)
        await model.applicationDidBecomeActive()
        #expect(loadCount == 0)

        hasAccess = true
        await model.applicationDidBecomeActive()

        #expect(loadCount == 1)
        #expect(model.screenPermissionGranted)
    }

    @Test("Unknown screen access requests permission once")
    @MainActor
    func unknownScreenAccessRequestsPermission() async {
        let preferences = UserDefaults(suiteName: UUID().uuidString)!
        var requestCount = 0
        let model = ClipTapeAppModel(
            preferences: preferences,
            screenAccessPreflight: { false },
            screenAccessRequest: {
                requestCount += 1
                return true
            },
            captureCatalogLoader: {
                CaptureCatalog.Snapshot(targets: [], currentApplication: nil)
            }
        )

        await model.refreshTargets(requestPermission: true)

        #expect(requestCount == 1)
        #expect(model.screenPermissionGranted)
    }
}

private struct TestFailure: Error {}

@MainActor
private enum TestVideoFactory {
    static func createSegment(at url: URL) async throws {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 32,
                AVVideoHeightKey: 32
            ]
        )
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: 32,
                kCVPixelBufferHeightKey as String: 32
            ]
        )

        guard writer.canAdd(input) else {
            throw TestFailure()
        }

        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        guard
            let pool = adaptor.pixelBufferPool,
            let pixelBuffer = makePixelBuffer(from: pool)
        else {
            throw TestFailure()
        }

        while !input.isReadyForMoreMediaData {
            await Task.yield()
        }

        guard adaptor.append(pixelBuffer, withPresentationTime: .zero) else {
            throw TestFailure()
        }

        while !input.isReadyForMoreMediaData {
            await Task.yield()
        }

        guard adaptor.append(
            pixelBuffer,
            withPresentationTime: CMTime(seconds: 1, preferredTimescale: 600)
        ) else {
            throw TestFailure()
        }

        input.markAsFinished()
        await writer.finishWriting()

        guard writer.status == .completed else {
            throw writer.error ?? TestFailure()
        }
    }

    private static func makePixelBuffer(from pool: CVPixelBufferPool) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(
            kCFAllocatorDefault,
            pool,
            &pixelBuffer
        )
        return status == kCVReturnSuccess ? pixelBuffer : nil
    }
}
