@preconcurrency import AVFoundation
import Foundation

struct RecordingSessionFiles: Sendable {
    let finalURL: URL
    let workingDirectory: URL
    private(set) var segmentURLs: [URL] = []

    static func create(
        in saveDirectory: URL,
        fileManager: FileManager = .default
    ) throws -> RecordingSessionFiles {
        let finalURL = RecordingFileNamer.availableURL(
            in: saveDirectory,
            fileManager: fileManager
        )
        let workingDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("MacTape", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(
            at: workingDirectory,
            withIntermediateDirectories: true
        )

        return RecordingSessionFiles(
            finalURL: finalURL,
            workingDirectory: workingDirectory
        )
    }

    func nextSegmentURL() -> URL {
        workingDirectory
            .appendingPathComponent("segment-\(segmentURLs.count + 1)")
            .appendingPathExtension("mp4")
    }

    mutating func appendSegment(_ url: URL) {
        segmentURLs.append(url)
    }

    mutating func removeLastSegment(fileManager: FileManager = .default) {
        guard let url = segmentURLs.popLast() else {
            return
        }

        try? fileManager.removeItem(at: url)
    }

    func discard(fileManager: FileManager = .default) {
        try? fileManager.removeItem(at: workingDirectory)
        try? fileManager.removeItem(at: finalURL)
    }
}

enum RecordingSegmentFinalizer {
    static func finalize(
        _ session: RecordingSessionFiles,
        fileManager: FileManager = .default
    ) async throws -> URL {
        guard let firstSegment = session.segmentURLs.first else {
            throw MacTapeCaptureError.noRecordingSegments
        }

        if session.segmentURLs.count == 1 {
            try fileManager.moveItem(at: firstSegment, to: session.finalURL)
            try? fileManager.removeItem(at: session.workingDirectory)
            return session.finalURL
        }

        let mergedURL = session.workingDirectory
            .appendingPathComponent("merged")
            .appendingPathExtension("mp4")
        try await Task.detached(priority: .userInitiated) {
            try await merge(session.segmentURLs, to: mergedURL)
        }.value
        try fileManager.moveItem(at: mergedURL, to: session.finalURL)
        try? fileManager.removeItem(at: session.workingDirectory)
        return session.finalURL
    }

    private static func merge(_ segmentURLs: [URL], to outputURL: URL) async throws {
        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        let audioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        var insertionTime = CMTime.zero
        var preferredTransform: CGAffineTransform?

        for segmentURL in segmentURLs {
            let asset = AVURLAsset(url: segmentURL)
            let duration = try await asset.load(.duration)
            let timeRange = CMTimeRange(start: .zero, duration: duration)

            guard let sourceVideoTrack = try await asset
                .loadTracks(withMediaType: .video)
                .first else {
                throw MacTapeCaptureError.noVideoTrack
            }

            try videoTrack?.insertTimeRange(
                timeRange,
                of: sourceVideoTrack,
                at: insertionTime
            )

            if preferredTransform == nil {
                preferredTransform = try await sourceVideoTrack.load(.preferredTransform)
            }

            if let sourceAudioTrack = try await asset
                .loadTracks(withMediaType: .audio)
                .first {
                try audioTrack?.insertTimeRange(
                    timeRange,
                    of: sourceAudioTrack,
                    at: insertionTime
                )
            }

            insertionTime = CMTimeAdd(insertionTime, duration)
        }

        videoTrack?.preferredTransform = preferredTransform ?? .identity

        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetPassthrough
        ) else {
            throw MacTapeCaptureError.finalizationFailed
        }

        try await exporter.export(to: outputURL, as: .mp4)
    }
}
