import SwiftUI

struct ServersView: View {
    @EnvironmentObject var session: Session
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
                            Text(loading ? "Loading\u{2026}" : "No servers yet")
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
                        .foregroundColor(.black)
                        .frame(width: 60, height: 60)
                        .background(Color.white)
                        .clipShape(Circle())
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
                // Only refetch when the tenant actually changed, not on every tab switch.
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
                    .foregroundColor(.white)
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
