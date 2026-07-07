import SwiftUI
import UIKit

@main
struct AltareApp: App {
    @StateObject private var session = Session()

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
            .preferredColorScheme(.dark)
            .tint(.white)
        }
    }

    static func configureAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(Theme.background)
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = .white

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Theme.background)
        UITabBar.appearance().standardAppearance = tab
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tab
        }
    }
}
