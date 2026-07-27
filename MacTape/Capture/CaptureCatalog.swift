import AppKit
import ScreenCaptureKit

enum CaptureCatalog {
    struct Snapshot {
        let targets: [CaptureTarget]
        let currentApplication: SCRunningApplication?
    }

    static func load() async throws -> Snapshot {
        let content = try await SCShareableContent.excludingDesktopWindows(
            true,
            onScreenWindowsOnly: true
        )

        let currentBundleIdentifier = Bundle.main.bundleIdentifier
        let currentApplication = content.applications.first {
            $0.bundleIdentifier == currentBundleIdentifier
        }

        let displays = content.displays
            .map { display in
                CaptureTarget(
                    id: "display-\(display.displayID)",
                    kind: .display,
                    title: displayName(for: display),
                    detail: "\(display.width) × \(display.height)",
                    source: .display(display)
                )
            }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }

        let windows = content.windows
            .filter { window in
                guard window.isOnScreen, window.frame.width >= 160, window.frame.height >= 90 else {
                    return false
                }

                return window.owningApplication?.bundleIdentifier != currentBundleIdentifier
            }
            .map { window in
                let applicationName = window.owningApplication?.applicationName ?? "Application"
                let windowTitle = window.title?.trimmingCharacters(in: .whitespacesAndNewlines)
                let title = windowTitle?.isEmpty == false ? windowTitle! : applicationName
                let detail = title == applicationName ? "Window" : applicationName

                return CaptureTarget(
                    id: "window-\(window.windowID)",
                    kind: .window,
                    title: title,
                    detail: detail,
                    source: .window(window)
                )
            }
            .sorted { lhs, rhs in
                if lhs.detail == rhs.detail {
                    return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                }

                return lhs.detail.localizedStandardCompare(rhs.detail) == .orderedAscending
            }

        return Snapshot(
            targets: displays + windows,
            currentApplication: currentApplication
        )
    }

    private static func displayName(for display: SCDisplay) -> String {
        NSScreen.screens.first { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }

            return number.uint32Value == display.displayID
        }?.localizedName ?? "Display \(display.displayID)"
    }
}
