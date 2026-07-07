import SwiftUI

struct AccountView: View {
    @EnvironmentObject var session: Session
    @State private var username = ""
    @State private var email = ""
    @State private var resources: TenantResources?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        profileHeader
                        resourcesCard
                        detailsCard
                        Button(role: .destructive) {
                            session.logout()
                        } label: {
                            Text("Log out")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .foregroundColor(Theme.red)
                    }
                    .padding(16)
                }
            }
            .toolbar { ToolbarItem(placement: .topBarLeading) { TenantMenu() } }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                username = session.me?.username ?? ""
                email = session.me?.email ?? ""
                await loadResources()
            }
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String((session.me?.username ?? "?").prefix(1)).uppercased())
                        .font(.title2.bold())
                        .foregroundColor(.white)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(session.me?.username ?? "\u{2014}").font(.headline).foregroundColor(.white)
                Text(session.me?.email ?? "").font(.subheadline).foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var resourcesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resources").font(.subheadline).foregroundColor(Theme.textSecondary)
            resourceLine("memorychip", "Memory", resources?.memory, gb: true)
            resourceLine("externaldrive", "Disk", resources?.disk, gb: true)
            resourceLine("bolt.fill", "CPU", resources?.cpu, gb: false)
            resourceLine("square.stack.3d.up", "Servers", resources?.servers, gb: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 20)
    }

    private func resourceLine(_ icon: String, _ title: String, _ usage: ResourceUsage?, gb: Bool) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(Theme.textSecondary).frame(width: 24)
            Text(title).foregroundColor(.white)
            Spacer()
            let used = usage?.used
            let total = usage?.total
            let usedText = gb ? Format.gb(used) : (used.map { Format.credits($0) } ?? "\u{2014}")
            let totalText = gb ? Format.gb(total) : (total.map { Format.credits($0) } ?? "\u{2014}")
            Text("\(usedText) / \(totalText)").foregroundColor(Theme.textSecondary)
        }
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Account details").font(.subheadline).foregroundColor(Theme.textSecondary)
            labeledField("Email", text: $email)
            labeledField("Username", text: $username)
            PrimaryButton(title: "Save") {
                Task { await save() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 20)
    }

    private func labeledField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundColor(Theme.textSecondary)
            TextField(label, text: text)
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Theme.field)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func loadResources() async {
        guard let tenant = session.currentTenant?.id else { return }
        resources = try? await session.api.get("api/tenants/\(tenant)/resources") as TenantResources
    }

    private func save() async {
        let body: [String: String] = ["username": username, "email": email]
        try? await session.api.patchVoid("api/auth/account", body: body)
        await session.loadProfileAndTenants()
    }
}
