import SwiftUI

struct ClipTapeSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(ClipTapeSpacing.medium)
            .background(ClipTapeColor.surface, in: .rect(cornerRadius: ClipTapeRadius.medium))
            .overlay {
                RoundedRectangle(cornerRadius: ClipTapeRadius.medium, style: .continuous)
                    .stroke(ClipTapeColor.separator.opacity(0.55), lineWidth: 0.5)
            }
    }
}
