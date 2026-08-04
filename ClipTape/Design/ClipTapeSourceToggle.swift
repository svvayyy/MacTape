import SwiftUI

struct ClipTapeSourceToggle: View {
    let title: String
    let subtitle: String
    let systemImageName: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ClipTapeSpacing.medium) {
                Image(systemName: systemImageName)
                    .font(.system(size: 14, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isEnabled ? ClipTapeColor.recording : ClipTapeColor.textSecondary)
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: ClipTapeSpacing.xSmall) {
                    Text(title)
                        .clipTapeText(.body)
                        .foregroundStyle(ClipTapeColor.textPrimary)

                    Text(subtitle)
                        .clipTapeText(.detail)
                }

                Spacer()

                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isEnabled ? ClipTapeColor.recording : ClipTapeColor.textSecondary.opacity(0.7))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isEnabled ? "On" : "Off")
    }
}
