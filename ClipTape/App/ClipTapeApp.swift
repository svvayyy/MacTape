import SwiftUI

@main
struct ClipTapeApp: App {
    @State private var appModel = ClipTapeAppModel()

    var body: some Scene {
        MenuBarExtra {
            ClipTapeRecorderView()
                .environment(appModel)
        } label: {
            Image(
                systemName: appModel.hasActiveRecordingSession
                    ? "record.circle.fill"
                    : "record.circle"
            )
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)

        Settings {
            ClipTapeSettingsView()
                .environment(appModel)
        }
    }
}
