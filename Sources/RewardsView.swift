import SwiftUI

struct RewardsView: View {
    @EnvironmentObject var session: Session
    @EnvironmentObject var settings: AppSettings
    @State private var rewards: RewardsInfo?
    @State private var earning = false
    @State private var loadedTenant: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        dailyCard
                        afkCard
                        referralCard
                    }
                    .padding(16)
                }
            }
            .toolbar { ToolbarItem(placement: .topBarLeading) { TenantMenu() } }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task(id: session.currentTenant?.id) {
                if session.currentTenant?.id != loadedTenant { await load() }
            }
        }
    }

    private var dailyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(settings.t("dailyReward")).font(.subheadline).foregroundColor(Theme.textSecondary)
            HStack(spacing: 10) {
                StatBox(value: Format.credits(rewards?.daily?.reward ?? 0), label: settings.t("reward"))
                StatBox(value: "\(rewards?.daily?.streak ?? 0)", label: settings.t("streak"))
                StatBox(value: "\(rewards?.daily?.nextStreak ?? 0)", label: settings.t("nextStreak"))
            }
            PrimaryButton(title: settings.t("claim"), systemImage: "gift") {
                Task { await claim() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 20)
    }

    private var afkCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(settings.t("afkRewards")).font(.subheadline).foregroundColor(Theme.textSecondary)
            HStack(spacing: 6) {
                Circle().fill(earning ? Theme.green : Color.gray).frame(width: 7, height: 7)
                Text(earning ? settings.t("earning") : settings.t("notEarning")).font(.caption).foregroundColor(Theme.textSecondary)
            }
            HStack(spacing: 10) {
                StatBox(value: Format.credits(rewards?.afk?.now ?? 0), label: settings.t("afkNow"))
                StatBox(value: String(format: "%.2f", rewards?.afk?.perMinute ?? 0), label: settings.t("perMinute"))
                StatBox(value: String(format: "%.1fx", rewards?.afk?.party ?? 1), label: settings.t("partyX"))
            }
            PrimaryButton(title: earning ? settings.t("stopEarning") : settings.t("startEarning"), systemImage: "bolt.fill") {
                Task { await toggleAfk() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 20)
    }

    private var referralCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(settings.t("referrals")).font(.subheadline).foregroundColor(Theme.textSecondary)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.t("yourCode")).font(.caption).foregroundColor(Theme.textSecondary)
                    Text(rewards?.referral?.code ?? "—")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = rewards?.referral?.code
                } label: {
                    Image(systemName: "doc.on.doc").foregroundColor(Theme.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 20)
    }

    private func load() async {
        guard let tenant = session.currentTenant?.id else { return }
        rewards = try? await session.api.get("api/tenants/\(tenant)/rewards") as RewardsInfo
        earning = rewards?.afk?.earning ?? false
        loadedTenant = tenant
    }

    private func claim() async {
        guard let tenant = session.currentTenant?.id else { return }
        try? await session.api.postVoid("api/tenants/\(tenant)/rewards/claim")
        await load()
    }

    private func toggleAfk() async {
        guard let tenant = session.currentTenant?.id else { return }
        let path = earning ? "api/tenants/\(tenant)/rewards/afk/stop" : "api/tenants/\(tenant)/rewards/afk/start"
        try? await session.api.postVoid(path)
        earning.toggle()
    }
}
