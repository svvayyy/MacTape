import SwiftUI

enum MacTapeSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 24
    static let xxLarge: CGFloat = 32
}

enum MacTapeRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 18
    static let capsule: CGFloat = 999
}

enum MacTapeColor {
    static let recording = Color(red: 0.92, green: 0.18, blue: 0.20)
    static let recordingPressed = Color(red: 0.78, green: 0.11, blue: 0.14)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let surfaceSecondary = Color(nsColor: .underPageBackgroundColor)
    static let textPrimary = Color(nsColor: .labelColor)
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
    static let separator = Color(nsColor: .separatorColor)
    static let success = Color(nsColor: .systemGreen)
    static let warning = Color(nsColor: .systemOrange)
}

enum MacTapeMotion {
    static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.84)
    static let settle = Animation.spring(response: 0.38, dampingFraction: 0.88)
}

enum MacTapeTextStyle {
    case title
    case section
    case body
    case detail
    case timer
    case button
}

struct MacTapeTextModifier: ViewModifier {
    let style: MacTapeTextStyle

    func body(content: Content) -> some View {
        switch style {
        case .title:
            content
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.2)
        case .section:
            content
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MacTapeColor.textSecondary)
        case .body:
            content
                .font(.system(size: 13, weight: .medium))
        case .detail:
            content
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(MacTapeColor.textSecondary)
        case .timer:
            content
                .font(.system(size: 34, weight: .medium, design: .rounded))
                .monospacedDigit()
                .tracking(-0.8)
        case .button:
            content
                .font(.system(size: 13, weight: .semibold))
        }
    }
}

extension View {
    func macTapeText(_ style: MacTapeTextStyle) -> some View {
        modifier(MacTapeTextModifier(style: style))
    }
}
