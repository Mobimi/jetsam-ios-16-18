import SwiftUI

public struct Theme {
    public static let bgPrimary = Color(red: 0.05, green: 0.06, blue: 0.09)
    public static let bgSecondary = Color(red: 0.09, green: 0.11, blue: 0.16)
    public static let bgCard = Color(red: 0.13, green: 0.16, blue: 0.22)
    public static let bgCardHover = Color(red: 0.17, green: 0.21, blue: 0.29)

    public static let accentCyan = Color(red: 0.0, green: 0.85, blue: 0.95)
    public static let accentPurple = Color(red: 0.65, green: 0.35, blue: 1.0)
    public static let accentGreen = Color(red: 0.15, green: 0.85, blue: 0.45)
    public static let accentAmber = Color(red: 1.0, green: 0.70, blue: 0.15)
    public static let accentRed = Color(red: 1.0, green: 0.25, blue: 0.35)

    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.7)
    public static let textTertiary = Color(white: 0.45)

    public static let gradientCyanPurple = LinearGradient(
        colors: [accentCyan, accentPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let gradientGreenCyan = LinearGradient(
        colors: [accentGreen, accentCyan],
        startPoint: .leading,
        endPoint: .trailing
    )

    public static let gradientCard = LinearGradient(
        colors: [bgCard.opacity(0.85), bgCard.opacity(0.65)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.4), radius: radius, x: 0, y: 0)
    }
}

extension View {
    public func glow(color: Color, radius: CGFloat = 8) -> some View {
        self.modifier(GlowModifier(color: color, radius: radius))
    }
}
