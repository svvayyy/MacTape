import AppKit
import ScreenCaptureKit

@MainActor
enum CaptureScreenshot {
    static func save(
        target: CaptureTarget,
        excluding application: SCRunningApplication?,
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
        let configuration = SCStreamConfiguration()
        configuration.width = Int(dimensions.width)
        configuration.height = Int(dimensions.height)
        configuration.showsCursor = true

        let image = try await SCScreenshotManager.captureImage(
            contentFilter: contentFilter,
            configuration: configuration
        )
        let representation = NSBitmapImageRep(cgImage: image)

        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw MacTapeCaptureError.screenshotEncodingFailed
        }

        try data.write(to: outputURL, options: .atomic)
    }
}
