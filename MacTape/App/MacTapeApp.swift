import SwiftUI

@main
struct MacTapeApp: App {
    @State private var appModel = MacTapeAppModel()

    var body: some Scene {
        MenuBarExtra {
            MacTapeRecorderView()
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
            MacTapeSettingsView()
                .environment(appModel)
        }
    }
}
