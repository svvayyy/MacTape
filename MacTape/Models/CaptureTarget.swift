import AppKit
import ScreenCaptureKit

struct CaptureTarget: Identifiable {
    enum Kind: String {
        case display
        case window
    }

    enum Source {
        case display(SCDisplay)
        case window(SCWindow)
    }

    let id: String
    let kind: Kind
    let title: String
    let detail: String
    let source: Source

    var symbolName: String {
        switch kind {
        case .display:
            "display"
        case .window:
            "macwindow"
        }
    }

    var accessibilityDescription: String {
        detail.isEmpty ? title : "\(title), \(detail)"
    }

    func contentFilter(excluding application: SCRunningApplication?) -> SCContentFilter {
        switch source {
        case .display(let display):
            SCContentFilter(
                display: display,
                excludingApplications: application.map { [$0] } ?? [],
                exceptingWindows: []
            )
        case .window(let window):
            SCContentFilter(desktopIndependentWindow: window)
        }
    }

    var pixelSize: CGSize {
        switch source {
        case .display(let display):
            return CGSize(width: display.width, height: display.height)
        case .window(let window):
            let scale = NSScreen.main?.backingScaleFactor ?? 2
            return CGSize(
                width: window.frame.width * scale,
                height: window.frame.height * scale
            )
        }
    }
}
