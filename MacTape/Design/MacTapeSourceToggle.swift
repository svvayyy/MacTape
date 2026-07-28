import SwiftUI

struct MacTapeSourceToggle: View {
    let title: String
    let subtitle: String
    let systemImageName: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MacTapeSpacing.medium) {
                Image(systemName: systemImageName)
                    .font(.system(size: 14, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isEnabled ? MacTapeColor.recording : MacTapeColor.textSecondary)
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: MacTapeSpacing.xSmall) {
                    Text(title)
                        .macTapeText(.body)
                        .foregroundStyle(MacTapeColor.textPrimary)

                    Text(subtitle)
                        .macTapeText(.detail)
                }

                Spacer()

                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isEnabled ? MacTapeColor.recording : MacTapeColor.textSecondary.opacity(0.7))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isEnabled ? "On" : "Off")
    }
}
