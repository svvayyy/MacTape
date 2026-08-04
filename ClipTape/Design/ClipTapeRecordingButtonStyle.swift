import SwiftUI

struct ClipTapeRecordingButtonStyle: ButtonStyle {
    let role: Role

    enum Role {
        case record
        case stop
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .clipTapeText(.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(backgroundColor(configuration: configuration), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(ClipTapeMotion.snappy, value: configuration.isPressed)
    }

    private func backgroundColor(configuration: Configuration) -> Color {
        if configuration.isPressed {
            return ClipTapeColor.recordingPressed
        }

        switch role {
        case .record:
            return ClipTapeColor.recording
        case .stop:
            return ClipTapeColor.recording
        }
    }
}

struct ClipTapeSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .clipTapeText(.button)
            .foregroundStyle(ClipTapeColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                ClipTapeColor.surface.opacity(configuration.isPressed ? 0.7 : 1),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(ClipTapeColor.separator.opacity(0.7), lineWidth: 0.5)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(ClipTapeMotion.snappy, value: configuration.isPressed)
    }
}
