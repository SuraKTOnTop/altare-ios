import SwiftUI

struct ServersView: View {
    @EnvironmentObject var session: Session
    @State private var servers: [Server] = []
    @State private var loading = false

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
                        .frame(width: 56, height: 56)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                }
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
            .task(id: session.currentTenant?.id) { await load() }
        }
    }

    private func load() async {
        guard let tenant = session.currentTenant?.id else { return }
        loading = true
        servers = (try? await session.api.getArray("api/tenants/\(tenant)/servers")) ?? []
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
