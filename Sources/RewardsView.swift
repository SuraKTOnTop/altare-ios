import SwiftUI

struct RewardsView: View {
    @EnvironmentObject var session: Session
    @State private var rewards: RewardsInfo?
    @State private var earning = false

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
            .task(id: session.currentTenant?.id) { await load() }
        }
    }

    private var dailyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Daily reward").font(.subheadline).foregroundColor(Theme.textSecondary)
            HStack(spacing: 10) {
                StatBox(value: Format.credits(rewards?.daily?.reward ?? 0), label: "Reward")
                StatBox(value: "\(rewards?.daily?.streak ?? 0)", label: "Streak")
                StatBox(value: "\(rewards?.daily?.nextStreak ?? 0)", label: "Next streak")
            }
            PrimaryButton(title: "Claim", systemImage: "gift") {
                Task { await claim() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 20)
    }

    private var afkCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("AFK rewards").font(.subheadline).foregroundColor(Theme.textSecondary)
            HStack(spacing: 6) {
                Circle().fill(earning ? Theme.green : Color.gray).frame(width: 7, height: 7)
                Text(earning ? "Earning" : "Not earning").font(.caption).foregroundColor(Theme.textSecondary)
            }
            HStack(spacing: 10) {
                StatBox(value: Format.credits(rewards?.afk?.now ?? 0), label: "AFK now")
                StatBox(value: String(format: "%.2f", rewards?.afk?.perMinute ?? 0), label: "Per minute")
                StatBox(value: String(format: "%.1fx", rewards?.afk?.party ?? 1), label: "Party x")
            }
            PrimaryButton(title: earning ? "Stop earning" : "Start earning", systemImage: "bolt.fill") {
                Task { await toggleAfk() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 20)
    }

    private var referralCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Referrals").font(.subheadline).foregroundColor(Theme.textSecondary)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your code").font(.caption).foregroundColor(Theme.textSecondary)
                    Text(rewards?.referral?.code ?? "\u{2014}")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = rewards?.referral?.code
                } label: {
                    Image(systemName: "doc.on.doc").foregroundColor(.white)
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
