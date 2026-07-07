import SwiftUI

struct WalletView: View {
    @EnvironmentObject var session: Session
    @EnvironmentObject var settings: AppSettings
    @State private var wallet: WalletInfo?
    @State private var loadedTenant: String?
    @State private var memory = 0.0
    @State private var disk = 0.0
    @State private var cpu = 0.0
    @State private var slots = 0.0

    // Default unit prices (from the original client); refreshed from the store endpoint when available.
    @State private var priceMemory = 0.43
    @State private var priceDisk = 0.04
    @State private var priceCpu = 6.0
    @State private var priceSlot = 250.0

    private var estimated: Double {
        memory * priceMemory + disk * priceDisk + cpu * priceCpu + slots * priceSlot
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        balanceCard
                        buyResourcesCard
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

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(settings.t("balance"), systemImage: "creditcard")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            Text("\(Format.credits(wallet?.amount ?? 0)) \(settings.t("credits"))")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            HStack(spacing: 12) {
                PrimaryButton(title: settings.t("addCredits"), systemImage: "plus") {}
                SecondaryButton(title: settings.t("transfer"), systemImage: "arrow.left.arrow.right") {}
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 20)
    }

    private var buyResourcesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(settings.t("buyResources")).font(.subheadline).foregroundColor(Theme.textSecondary)
            resourceRow("memorychip", settings.t("memory"), "\(Format.credits(priceMemory)) cr / MB", $memory, step: 512, unit: "MB")
            resourceRow("externaldrive", settings.t("disk"), "\(Format.credits(priceDisk)) cr / MB", $disk, step: 1024, unit: "MB")
            resourceRow("bolt.fill", settings.t("cpu"), "\(Format.credits(priceCpu)) cr / %", $cpu, step: 25, unit: "%")
            resourceRow("square.stack.3d.up", settings.t("serverSlots"), "\(Format.credits(priceSlot)) cr", $slots, step: 1, unit: "")
            Divider().overlay(Color.primary.opacity(0.1))
            HStack {
                Text(settings.t("estimatedCost")).foregroundColor(Theme.textSecondary)
                Spacer()
                Text("\(Format.credits(estimated)) \(settings.t("credits"))").foregroundColor(Theme.textPrimary).fontWeight(.semibold)
            }
            PrimaryButton(title: settings.t("purchase"), enabled: estimated > 0) {
                Task { await purchase() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 20)
    }

    private func resourceRow(_ icon: String, _ title: String, _ subtitle: String, _ value: Binding<Double>, step: Double, unit: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(Theme.textSecondary).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundColor(Theme.textPrimary)
                Text(subtitle).font(.caption).foregroundColor(Theme.textSecondary)
            }
            Spacer()
            Button { value.wrappedValue = max(0, value.wrappedValue - step) } label: {
                Image(systemName: "minus").frame(width: 28, height: 28)
            }
            Text("\(Int(value.wrappedValue)) \(unit)")
                .foregroundColor(Theme.textPrimary)
                .frame(minWidth: 66)
            Button { value.wrappedValue += step } label: {
                Image(systemName: "plus").frame(width: 28, height: 28)
            }
        }
        .foregroundColor(Theme.accent)
    }

    private func load() async {
        guard let tenant = session.currentTenant?.id else { return }
        // Fetch balance and store prices in parallel.
        async let walletResult: WalletInfo? = try? await session.api.get("api/tenants/\(tenant)/wallet")
        async let pricesResult: StorePrices? = try? await session.api.get("api/tenants/\(tenant)/store/prices")
        let (w, prices) = await (walletResult, pricesResult)
        wallet = w
        if let prices {
            priceMemory = prices.memory ?? priceMemory
            priceDisk = prices.disk ?? priceDisk
            priceCpu = prices.cpu ?? priceCpu
            priceSlot = prices.slots ?? priceSlot
        }
        loadedTenant = tenant
    }

    private func purchase() async {
        guard let tenant = session.currentTenant?.id else { return }
        let body: [String: Double] = ["memory": memory, "disk": disk, "cpu": cpu, "slots": slots]
        try? await session.api.postVoid("api/tenants/\(tenant)/store/purchase", body: body)
        await load()
    }
}
