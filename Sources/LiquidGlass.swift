import SwiftUI

/// A UIKit blur wrapped for SwiftUI — the base layer for the glass effect.
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

/// "Liquid glass" background: a translucent blurred material tinted with an
/// accent color, finished with a soft top gloss, a thin rim and a colored
/// shadow. Works on iOS 16+ (no iOS 26-only APIs required).
struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 14
    var tint: Color = Theme.accent
    var prominent: Bool = true

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content
            .background(
                ZStack {
                    BlurView(style: prominent ? .systemUltraThinMaterial : .systemThinMaterial)
                    tint.opacity(prominent ? 0.85 : 0.14)
                    LinearGradient(
                        colors: [Color.white.opacity(prominent ? 0.35 : 0.18), Color.white.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
                .clipShape(shape)
            )
            .overlay(
                shape.stroke(Color.white.opacity(prominent ? 0.35 : 0.18), lineWidth: 1)
            )
            .clipShape(shape)
            .shadow(color: tint.opacity(prominent ? 0.35 : 0.0), radius: 12, x: 0, y: 6)
    }
}

extension View {
    /// Preferred entry point for the glass effect.
    func glass(cornerRadius: CGFloat = 14, tint: Color? = nil, prominent: Bool = true) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius, tint: tint ?? Theme.accent, prominent: prominent))
    }

    /// Backwards-compatible alias kept for earlier call sites.
    func liquidGlass(cornerRadius: CGFloat = 14, tint: Color? = nil, strong: Bool = true) -> some View {
        glass(cornerRadius: cornerRadius, tint: tint, prominent: strong)
    }
}

/// Press-scale animation shared by the glass buttons.
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
