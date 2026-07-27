import SwiftUI

struct MacTapeRecordingButtonStyle: ButtonStyle {
    let role: Role

    enum Role {
        case record
        case stop
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .macTapeText(.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(backgroundColor(configuration: configuration), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(MacTapeMotion.snappy, value: configuration.isPressed)
    }

    private func backgroundColor(configuration: Configuration) -> Color {
        if configuration.isPressed {
            return MacTapeColor.recordingPressed
        }

        switch role {
        case .record:
            return MacTapeColor.recording
        case .stop:
            return MacTapeColor.recording
        }
    }
}
