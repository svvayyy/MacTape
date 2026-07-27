import SwiftUI

struct MacTapeSettingsView: View {
    @Environment(MacTapeAppModel.self) private var appModel

    var body: some View {
        Form {
            Section("Recordings") {
                LabeledContent("Save folder") {
                    Button(appModel.saveDirectory.lastPathComponent) {
                        appModel.chooseSaveDirectory()
                    }
                }

                Toggle(
                    "Include system audio by default",
                    isOn: Binding(
                        get: { appModel.isSystemAudioEnabled },
                        set: { appModel.isSystemAudioEnabled = $0 }
                    )
                )

                Toggle(
                    "Include microphone by default",
                    isOn: Binding(
                        get: { appModel.isMicrophoneEnabled },
                        set: { value in
                            Task {
                                await appModel.setMicrophoneEnabled(value)
                            }
                        }
                    )
                )
            }

            Section("Privacy") {
                Text("MacTape records locally. Nothing is uploaded or analyzed.")
                    .foregroundStyle(MacTapeColor.textSecondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 260)
    }
}
