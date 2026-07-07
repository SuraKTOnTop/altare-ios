import SwiftUI
import UIKit

// MARK: - Liquid glass (iOS 15+ compatible)
//
// Telegram's "liquid glass" buttons do NOT rely on the iOS 26 `UIGlassEffect`
// API. On older systems they render their own glass: a real backdrop blur
// (UIVisualEffectView) plus a light refraction / specular highlight and a
// bright hairline rim. This file reproduces that approach so it looks the same
// all the way down to iOS 15, and simply looks a touch cleaner on newer ones.

/// Real backdrop blur (samples whatever is behind the view), bridged from UIKit.
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemUltraThinMaterial

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

/// Liquid-glass surface: blur + tint + top specular highlight + rim light.
struct LiquidGlass: ViewModifier {
    var cornerRadius: CGFloat? = nil   // nil == capsule
    var tint: Color? = nil
    var strong: Bool = false

    private var shape: AnyShape {
        if let cornerRadius {
            return AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        return AnyShape(Capsule())
    }

    func body(content: Content) -> some View {
        content
            // 1. Real backdrop blur (the actual "glass").
            .background(BlurView(style: .systemUltraThinMaterial).clipShape(shape))
            // 2. Colour tint so the glass carries the accent colour.
            .background(shape.fill((tint ?? .clear).opacity(strong ? 0.28 : 0.14)))
            // 3. Curved specular highlight sweeping from the top edge.
            .overlay(
                shape.fill(
                    LinearGradient(
                        colors: [.white.opacity(0.45), .white.opacity(0.08), .clear,
                                 .white.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
            )
            // 4. Bright rim light around the edge (the glass "bevel").
            .overlay(
                shape.stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.85), .white.opacity(0.25),
                                 .white.opacity(0.05), .white.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
                .allowsHitTesting(false)
            )
            .clipShape(shape)
            .shadow(color: .black.opacity(0.30), radius: 14, x: 0, y: 8)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat? = nil, tint: Color? = nil, strong: Bool = false) -> some View {
        modifier(LiquidGlass(cornerRadius: cornerRadius, tint: tint, strong: strong))
    }
}

/// Springy press feedback for glass buttons.
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? 0.06 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
