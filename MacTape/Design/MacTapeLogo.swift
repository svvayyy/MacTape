import SwiftUI

struct MacTapeLogo: View {
    let width: CGFloat

    init(width: CGFloat = 22) {
        self.width = width
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(
                cornerRadius: width * 0.18,
                style: .continuous
            )
            .stroke(
                MacTapeColor.recording,
                lineWidth: max(2, width * 0.11)
            )
            .frame(
                width: width * 0.86,
                height: width * 0.64
            )
            .padding(.trailing, width * 0.14)
            .padding(.bottom, width * 0.14)

            Circle()
                .fill(MacTapeColor.recording)
                .padding(width * 0.07)
                .background(Circle().fill(.background))
                .frame(
                    width: width * 0.45,
                    height: width * 0.45
                )
        }
        .frame(width: width, height: width * 0.82)
        .accessibilityHidden(true)
    }
}
