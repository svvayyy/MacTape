import SwiftUI

struct ClipTapeStatusPill: View {
    let title: String
    let color: Color
    let pulses: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isEmphasized = false

    var body: some View {
        HStack(spacing: ClipTapeSpacing.small) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .scaleEffect(isEmphasized ? 1.18 : 1)
                .opacity(isEmphasized ? 0.72 : 1)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ClipTapeColor.textSecondary)
        }
        .padding(.horizontal, ClipTapeSpacing.medium)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.7), in: Capsule())
        .onAppear {
            guard pulses, !reduceMotion else {
                return
            }

            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isEmphasized = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}
