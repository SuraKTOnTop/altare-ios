import SwiftUI

enum Theme {
    static let background = Color(hex: 0x0B0B0C)
    static let card = Color(hex: 0x151518)
    static let field = Color(hex: 0x1C1C20)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let green = Color(hex: 0x37C871)
    static let red = Color(hex: 0xE23B3B)
    static let orange = Color(hex: 0xE0952B)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16, radius: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

enum Format {
    /// Values from the API are assumed to be in MB; convert to GB for display.
    static func gb(_ value: Double?) -> String {
        guard let value else { return "\u{2014}" }
        let gb = value >= 1024 ? value / 1024 : value
        return String(format: "%.1f GB", gb)
    }

    static func percent(_ value: Double?) -> String {
        guard let value else { return "\u{2014}" }
        return String(format: "%.0f%%", value)
    }

    static func credits(_ value: Double) -> String {
        if value == value.rounded() { return String(format: "%.0f", value) }
        return String(format: "%.2f", value)
    }
}

// MARK: - Shared components

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
            .padding(.vertical, 16)
            .foregroundColor(.black)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
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
                Text(title).fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundColor(.white)
            .background(Color.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct StatBox: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 6) {
            Text(value).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
            Text(label).font(.caption).foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct StatusBadge: View {
    let status: String
    private var color: Color {
        switch status.lowercased() {
        case "running", "online", "active": return Theme.green
        case "starting", "stopping": return Theme.orange
        case "offline", "stopped": return Theme.red
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
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }
}

struct IconStat: View {
    let system: String
    let text: String
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: system).font(.caption2).foregroundColor(Theme.textSecondary)
            Text(text).font(.caption).foregroundColor(Theme.textSecondary)
        }
    }
}

struct TenantMenu: View {
    @EnvironmentObject var session: Session
    var body: some View {
        Menu {
            ForEach(session.tenants) { tenant in
                Button(tenant.name ?? tenant.id) { session.currentTenant = tenant }
            }
        } label: {
            HStack(spacing: 4) {
                Text(session.currentTenant?.name ?? "\u{2014}")
                    .font(.title3.weight(.semibold))
                Image(systemName: "chevron.down").font(.caption2)
            }
            .foregroundColor(.white)
        }
    }
}
