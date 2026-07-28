import CoreGraphics

enum CaptureDimensions {
    static let maximumDimension = 6_016

    static func sourcePixelSize(
        contentRect: CGRect,
        pointPixelScale: CGFloat
    ) -> CGSize {
        let scale = pointPixelScale > 0 ? pointPixelScale : 1

        return CGSize(
            width: contentRect.width * scale,
            height: contentRect.height * scale
        )
    }

    static func fittedPixelSize(
        for sourceSize: CGSize,
        resolution: CaptureResolution = .source
    ) -> CGSize {
        guard sourceSize.width > 0, sourceSize.height > 0 else {
            return CGSize(width: 1_920, height: 1_080)
        }

        let maximumSize = resolution.maximumSize(for: sourceSize)
            ?? CGSize(width: maximumDimension, height: maximumDimension)
        let scale = min(
            1,
            maximumSize.width / sourceSize.width,
            maximumSize.height / sourceSize.height
        )
        let width = evenInteger(sourceSize.width * scale)
        let height = evenInteger(sourceSize.height * scale)

        return CGSize(width: max(2, width), height: max(2, height))
    }

    private static func evenInteger(_ value: CGFloat) -> CGFloat {
        let integer = Int(value.rounded(.down))
        return CGFloat(integer - integer % 2)
    }
}
