import SwiftUI

struct MacTapeTargetPicker: View {
    @Environment(MacTapeAppModel.self) private var appModel

    var body: some View {
        Menu {
            if !displayTargets.isEmpty {
                Section("Displays") {
                    targetButtons(displayTargets)
                }
            }

            if !windowTargets.isEmpty {
                Section("Windows") {
                    targetButtons(windowTargets)
                }
            }
        } label: {
            HStack(spacing: MacTapeSpacing.medium) {
                Image(systemName: appModel.selectedTarget?.symbolName ?? "display")
                    .font(.system(size: 15, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(MacTapeColor.textSecondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: MacTapeSpacing.xSmall) {
                    Text(appModel.selectedTarget?.title ?? "Choose a target")
                        .macTapeText(.body)
                        .foregroundStyle(MacTapeColor.textPrimary)
                        .lineLimit(1)

                    Text(appModel.selectedTarget?.detail ?? "Display or window")
                        .macTapeText(.detail)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(MacTapeColor.textSecondary)
            }
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .accessibilityLabel("Capture target")
        .accessibilityValue(appModel.selectedTarget?.accessibilityDescription ?? "Not selected")
    }

    private var displayTargets: [CaptureTarget] {
        appModel.captureTargets.filter { $0.kind == .display }
    }

    private var windowTargets: [CaptureTarget] {
        appModel.captureTargets.filter { $0.kind == .window }
    }

    @ViewBuilder
    private func targetButtons(_ targets: [CaptureTarget]) -> some View {
        ForEach(targets) { target in
            Button {
                appModel.selectedTargetID = target.id
            } label: {
                Label {
                    Text(target.title)
                } icon: {
                    Image(systemName: target.id == appModel.selectedTargetID ? "checkmark" : target.symbolName)
                }
            }
        }
    }
}
