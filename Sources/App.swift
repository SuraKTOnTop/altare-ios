import SwiftUI
import UIKit

@main
struct AltareApp: App {
    @StateObject private var session = Session()
    @StateObject private var settings = AppSettings()

    init() { AltareApp.configureAppearance() }

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isAuthenticated {
                    RootView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(session)
            .environmentObject(settings)
            .preferredColorScheme(settings.themeMode.colorScheme)
            .tint(Theme.accent)
            .environment(\.locale, Locale(identifier: settings.language.resolved))
        }
    }

    static func configureAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = Theme.uiBackground
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: UIColor.label]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = Theme.uiAccent

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = Theme.uiBackground
        UITabBar.appearance().standardAppearance = tab
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tab
        }
        UITabBar.appearance().tintColor = Theme.uiAccent
    }
}
