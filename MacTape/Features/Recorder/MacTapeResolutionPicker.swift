import SwiftUI

struct MacTapeResolutionPicker: View {
    @Environment(MacTapeAppModel.self) private var appModel

    var body: some View {
        HStack(spacing: MacTapeSpacing.medium) {
            Image(systemName: "rectangle.inset.filled")
                .font(.system(size: 14, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(MacTapeColor.textSecondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: MacTapeSpacing.xSmall) {
                Text("Output")
                    .macTapeText(.body)

                Text(appModel.outputResolution.detail)
                    .macTapeText(.detail)
            }

            Spacer()

            Picker(
                "Output resolution",
                selection: Binding(
                    get: { appModel.outputResolution },
                    set: { appModel.outputResolution = $0 }
                )
            ) {
                ForEach(CaptureResolution.allCases) { resolution in
                    Text(resolution.title)
                        .tag(resolution)
                }
            }
            .labelsHidden()
            .frame(width: 96)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Output resolution")
        .accessibilityValue(appModel.outputResolution.title)
    }
}
