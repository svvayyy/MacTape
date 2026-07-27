import CoreGraphics

enum CaptureDimensions {
    static let maximumDimension = 6_016

    static func fittedPixelSize(for sourceSize: CGSize) -> CGSize {
        guard sourceSize.width > 0, sourceSize.height > 0 else {
            return CGSize(width: 1_920, height: 1_080)
        }

        let largestDimension = max(sourceSize.width, sourceSize.height)
        let scale = min(1, CGFloat(maximumDimension) / largestDimension)
        let width = evenInteger(sourceSize.width * scale)
        let height = evenInteger(sourceSize.height * scale)

        return CGSize(width: max(2, width), height: max(2, height))
    }

    private static func evenInteger(_ value: CGFloat) -> CGFloat {
        let integer = Int(value.rounded(.down))
        return CGFloat(integer - integer % 2)
    }
}
