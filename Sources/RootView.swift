import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: Session
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        TabView {
            ServersView()
                .tabItem { Label(settings.t("tabServers"), systemImage: "square.stack.3d.up.fill") }
            WalletView()
                .tabItem { Label(settings.t("tabWallet"), systemImage: "creditcard.fill") }
            RewardsView()
                .tabItem { Label(settings.t("tabRewards"), systemImage: "gift.fill") }
            AccountView()
                .tabItem { Label(settings.t("tabAccount"), systemImage: "person.fill") }
        }
        .tint(Theme.accent)
        .task { await session.bootstrap() }
    }
}
