import SwiftUI

struct MacTapeSourceToggle: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MacTapeSpacing.medium) {
                Image(systemName: symbolName)
                    .font(.system(size: 14, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isEnabled ? MacTapeColor.recording : MacTapeColor.textSecondary)
                    .frame(width: 20)

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
