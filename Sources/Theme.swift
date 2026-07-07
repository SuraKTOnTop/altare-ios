import SwiftUI
import UIKit

// MARK: - Color helpers

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
    /// A color that adapts between light and dark appearance.
    static func dyn(light: UInt, dark: UInt) -> Color {
        Color(UIColor.dyn(light: light, dark: dark))
    }
}

extension UIColor {
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
    static func dyn(light: UInt, dark: UInt) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}

// MARK: - Theme palette

enum Theme {
    static let accent = Color(hex: 0x2F6BFF)
    static let uiAccent = UIColor(hex: 0x2F6BFF)

    static let background = Color.dyn(light: 0xF2F3F7, dark: 0x0B0D12)
    static let uiBackground = UIColor.dyn(light: 0xF2F3F7, dark: 0x0B0D12)

    static let card = Color.dyn(light: 0xFFFFFF, dark: 0x161A22)
    static let field = Color.dyn(light: 0xFFFFFF, dark: 0x1E2430)

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary

    static let red = Color(hex: 0xFF4D4F)
    static let green = Color(hex: 0x34C759)
}

// MARK: - Card

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundColor(.white)
            .glass(cornerRadius: 14, tint: Theme.accent, prominent: true)
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(enabled ? 1 : 0.5)
        .disabled(!enabled)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundColor(Theme.accent)
            .glass(cornerRadius: 14, prominent: false)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Small components

struct StatBox: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.headline).foregroundColor(Theme.textPrimary)
            Text(label).font(.caption).foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.field)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct StatusBadge: View {
    let status: String
    private var color: Color {
        switch status.lowercased() {
        case "running", "online", "active": return Theme.green
        case "starting", "installing": return .orange
        case "stopping", "offline", "stopped": return Theme.red
        default: return .gray
        }
    }
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(status.capitalized).font(.caption).foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct IconStat: View {
    let system: String
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: system).font(.caption).foregroundColor(Theme.textSecondary)
            Text(text).font(.caption).foregroundColor(Theme.textSecondary)
        }
    }
}

struct TenantMenu: View {
    @EnvironmentObject var session: Session
    var body: some View {
        Menu {
            ForEach(session.tenants) { tenant in
                Button {
                    session.currentTenant = tenant
                } label: {
                    if session.currentTenant?.id == tenant.id {
                        Label(tenant.name ?? tenant.id, systemImage: "checkmark")
                    } else {
                        Text(tenant.name ?? tenant.id)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(session.currentTenant?.name ?? "Altare")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
}

// MARK: - Formatting helpers

enum Format {
    static func credits(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(format: "%.2f", value)
    }
    static func gb(_ mb: Double?) -> String {
        guard let mb else { return "—" }
        if mb >= 1024 { return String(format: "%.1f GB", mb / 1024) }
        return "\(Int(mb)) MB"
    }
    static func percent(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value))%"
    }
}
