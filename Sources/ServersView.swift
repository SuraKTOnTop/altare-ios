import SwiftUI

struct ServersView: View {
    @EnvironmentObject var session: Session
    @EnvironmentObject var settings: AppSettings
    @State private var servers: [Server] = []
    @State private var loading = false
    @State private var loadedTenant: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(servers) { server in
                            NavigationLink(value: server.id) {
                                ServerCard(server: server)
                            }
                            .buttonStyle(.plain)
                        }
                        if servers.isEmpty {
                            Text(loading ? settings.t("loading") : settings.t("noServers"))
                                .foregroundColor(Theme.textSecondary)
                                .padding(.top, 80)
                        }
                    }
                    .padding(16)
                }
                .refreshable { await load() }

                Button {
                    // Server creation happens on the web dashboard.
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .glass(cornerRadius: 30, tint: Theme.accent)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(22)
            }
            .navigationDestination(for: String.self) { id in
                ServerDetailView(serverId: id)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { TenantMenu() }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task(id: session.currentTenant?.id) {
                if session.currentTenant?.id != loadedTenant { await load() }
            }
        }
    }

    private func load() async {
        guard let tenant = session.currentTenant?.id else { return }
        loading = true
        servers = (try? await session.api.getArray("api/tenants/\(tenant)/servers")) ?? []
        loadedTenant = tenant
        loading = false
    }
}

struct ServerCard: View {
    let server: Server
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(server.name ?? server.id)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                StatusBadge(status: server.displayStatus)
            }
            HStack(spacing: 18) {
                IconStat(system: "memorychip", text: Format.gb(server.limits?.memory))
                IconStat(system: "externaldrive", text: Format.gb(server.limits?.disk))
                IconStat(system: "bolt.fill", text: Format.percent(server.limits?.cpu))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
