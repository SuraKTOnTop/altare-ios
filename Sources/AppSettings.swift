import SwiftUI

/// The three appearance modes the user can pick from.
enum ThemeMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    /// nil lets the OS decide (used for `.system`).
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    var titleKey: String {
        switch self {
        case .system: return "themeSystem"
        case .light: return "themeLight"
        case .dark: return "themeDark"
        }
    }
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

/// App-wide user preferences (theme + language), persisted to UserDefaults.
@MainActor
final class AppSettings: ObservableObject {
    @Published var themeMode: ThemeMode {
        didSet { UserDefaults.standard.set(themeMode.rawValue, forKey: themeKey) }
    }
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: langKey) }
    }

    private let themeKey = "altare.theme"
    private let langKey = "altare.lang"

    init() {
        let savedTheme = UserDefaults.standard.string(forKey: themeKey)
        themeMode = ThemeMode(rawValue: savedTheme ?? "") ?? .system
        let savedLang = UserDefaults.standard.string(forKey: langKey)
        language = AppLanguage(rawValue: savedLang ?? "") ?? .system
    }

    /// Localizes a key using the currently selected language.
    func t(_ key: String) -> String {
        Loc.t(key, language.resolved)
    }
}
