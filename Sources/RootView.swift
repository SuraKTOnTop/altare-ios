import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: Session

    var body: some View {
        TabView {
            ServersView()
                .tabItem { Label("Servers", systemImage: "square.stack.3d.up.fill") }
            WalletView()
                .tabItem { Label("Wallet", systemImage: "creditcard.fill") }
            RewardsView()
                .tabItem { Label("Rewards", systemImage: "gift.fill") }
            AccountView()
                .tabItem { Label("Account", systemImage: "person.fill") }
        }
        .tint(.white)
        .task { await session.bootstrap() }
    }
}
