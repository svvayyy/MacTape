import SwiftUI

struct ClipTapeResolutionPicker: View {
    @Environment(ClipTapeAppModel.self) private var appModel

    var body: some View {
        HStack(spacing: ClipTapeSpacing.medium) {
            Image(systemName: "rectangle.inset.filled")
                .font(.system(size: 14, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(ClipTapeColor.textSecondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: ClipTapeSpacing.xSmall) {
                Text("Output")
                    .clipTapeText(.body)

                Text(appModel.outputResolution.detail)
                    .clipTapeText(.detail)
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
