import CoreGraphics

enum CaptureResolution: String, CaseIterable, Identifiable {
    case source
    case ultraHD
    case quadHD
    case fullHD
    case hd

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .source:
            "Original"
        case .ultraHD:
            "4K"
        case .quadHD:
            "1440p"
        case .fullHD:
            "1080p"
        case .hd:
            "720p"
        }
    }

    var detail: String {
        switch self {
        case .source:
            "Source size"
        case .ultraHD:
            "Up to 3840 × 2160"
        case .quadHD:
            "Up to 2560 × 1440"
        case .fullHD:
            "Up to 1920 × 1080"
        case .hd:
            "Up to 1280 × 720"
        }
    }

    func maximumSize(for sourceSize: CGSize) -> CGSize? {
        let landscape = sourceSize.width >= sourceSize.height

        switch self {
        case .source:
            return nil
        case .ultraHD:
            return landscape
                ? CGSize(width: 3_840, height: 2_160)
                : CGSize(width: 2_160, height: 3_840)
        case .quadHD:
            return landscape
                ? CGSize(width: 2_560, height: 1_440)
                : CGSize(width: 1_440, height: 2_560)
        case .fullHD:
            return landscape
                ? CGSize(width: 1_920, height: 1_080)
                : CGSize(width: 1_080, height: 1_920)
        case .hd:
            return landscape
                ? CGSize(width: 1_280, height: 720)
                : CGSize(width: 720, height: 1_280)
        }
    }
}
