import SwiftUI

struct AccountView: View {
    @EnvironmentObject var session: Session
    @EnvironmentObject var settings: AppSettings
    @State private var username = ""
    @State private var email = ""
    @State private var resources: TenantResources?
    @State private var loadedTenant: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        profileHeader
                        resourcesCard
                        detailsCard
                        settingsCard
                        Button(role: .destructive) {
                            session.logout()
                        } label: {
                            Text(settings.t("logOut"))
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
            .task(id: session.currentTenant?.id) {
                if session.currentTenant?.id != loadedTenant { await loadResources() }
            }
            .onAppear { fillFields() }
            .onChange(of: session.me?.id) { _ in fillFields(force: true) }
        }
    }

    /// Populates the editable fields from the loaded profile.
    private func fillFields(force: Bool = false) {
        if force || username.isEmpty { username = session.me?.username ?? username }
        if force || email.isEmpty { email = session.me?.email ?? email }
    }

    private var profileHeader: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Theme.accent.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String((session.me?.username ?? "?").prefix(1)).uppercased())
                        .font(.title2.bold())
                        .foregroundColor(Theme.accent)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(session.me?.username ?? "—").font(.headline).foregroundColor(Theme.textPrimary)
                Text(session.me?.email ?? "").font(.subheadline).foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var resourcesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settings.t("resources")).font(.subheadline).foregroundColor(Theme.textSecondary)
            resourceLine("memorychip", settings.t("memory"), resources?.memory, gb: true)
            resourceLine("externaldrive", settings.t("disk"), resources?.disk, gb: true)
            resourceLine("bolt.fill", settings.t("cpu"), resources?.cpu, gb: false)
            resourceLine("square.stack.3d.up", settings.t("tabServers"), resources?.servers, gb: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 20)
    }

    private func resourceLine(_ icon: String, _ title: String, _ usage: ResourceUsage?, gb: Bool) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(Theme.textSecondary).frame(width: 24)
            Text(title).foregroundColor(Theme.textPrimary)
            Spacer()
            let used = usage?.used
            let total = usage?.total
            let usedText = gb ? Format.gb(used) : (used.map { Format.credits($0) } ?? "—")
            let totalText = gb ? Format.gb(total) : (total.map { Format.credits($0) } ?? "—")
            Text("\(usedText) / \(totalText)").foregroundColor(Theme.textSecondary)
        }
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(settings.t("accountDetails")).font(.subheadline).foregroundColor(Theme.textSecondary)
            labeledField(settings.t("email"), text: $email)
            labeledField(settings.t("username"), text: $username)
            PrimaryButton(title: settings.t("save")) {
                Task { await save() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 20)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(settings.t("settings")).font(.subheadline).foregroundColor(Theme.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Label(settings.t("appearance"), systemImage: "circle.lefthalf.filled")
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)
                Picker("", selection: $settings.themeMode) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(settings.t(mode.titleKey)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack {
                Label(settings.t("language"), systemImage: "globe")
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Menu {
                    Picker("", selection: $settings.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang == .system ? settings.t("languageSystem") : lang.displayName).tag(lang)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(settings.language == .system ? settings.t("languageSystem") : settings.language.displayName)
                        Image(systemName: "chevron.up.chevron.down").font(.caption2)
                    }
                    .foregroundColor(Theme.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 20)
    }

    private func labeledField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundColor(Theme.textSecondary)
            TextField(label, text: text)
                .foregroundColor(Theme.textPrimary)
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
        loadedTenant = tenant
    }

    private func save() async {
        let body: [String: String] = ["username": username, "email": email]
        try? await session.api.patchVoid("api/auth/account", body: body)
        await session.loadProfileAndTenants()
    }
}
