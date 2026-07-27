import SwiftUI

struct MacTapeSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(MacTapeSpacing.medium)
            .background(MacTapeColor.surface, in: .rect(cornerRadius: MacTapeRadius.medium))
            .overlay {
                RoundedRectangle(cornerRadius: MacTapeRadius.medium, style: .continuous)
                    .stroke(MacTapeColor.separator.opacity(0.55), lineWidth: 0.5)
            }
    }
}
