import SwiftUI

struct WalletView: View {
    @EnvironmentObject var session: Session
    @State private var wallet: WalletInfo?
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
            .task(id: session.currentTenant?.id) { await load() }
        }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Balance", systemImage: "creditcard")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            Text("\(Format.credits(wallet?.amount ?? 0)) credits")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
            HStack(spacing: 12) {
                PrimaryButton(title: "Add credits", systemImage: "plus") {}
                SecondaryButton(title: "Transfer", systemImage: "arrow.left.arrow.right") {}
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 20)
    }

    private var buyResourcesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Buy resources").font(.subheadline).foregroundColor(Theme.textSecondary)
            resourceRow("memorychip", "Memory", "\(Format.credits(priceMemory)) cr / MB", $memory, step: 512, unit: "MB")
            resourceRow("externaldrive", "Disk", "\(Format.credits(priceDisk)) cr / MB", $disk, step: 1024, unit: "MB")
            resourceRow("bolt.fill", "CPU", "\(Format.credits(priceCpu)) cr / %", $cpu, step: 25, unit: "%")
            resourceRow("square.stack.3d.up", "Server slots", "\(Format.credits(priceSlot)) cr each", $slots, step: 1, unit: "")
            Divider().overlay(Color.white.opacity(0.1))
            HStack {
                Text("Estimated cost").foregroundColor(Theme.textSecondary)
                Spacer()
                Text("\(Format.credits(estimated)) credits").foregroundColor(.white).fontWeight(.semibold)
            }
            PrimaryButton(title: "Purchase", enabled: estimated > 0) {
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
                Text(title).foregroundColor(.white)
                Text(subtitle).font(.caption).foregroundColor(Theme.textSecondary)
            }
            Spacer()
            Button { value.wrappedValue = max(0, value.wrappedValue - step) } label: {
                Image(systemName: "minus").frame(width: 28, height: 28)
            }
            Text("\(Int(value.wrappedValue)) \(unit)")
                .foregroundColor(.white)
                .frame(minWidth: 66)
            Button { value.wrappedValue += step } label: {
                Image(systemName: "plus").frame(width: 28, height: 28)
            }
        }
        .foregroundColor(.white)
    }

    private func load() async {
        guard let tenant = session.currentTenant?.id else { return }
        wallet = try? await session.api.get("api/tenants/\(tenant)/wallet") as WalletInfo
        if let prices = try? await session.api.get("api/tenants/\(tenant)/store/prices") as StorePrices {
            priceMemory = prices.memory ?? priceMemory
            priceDisk = prices.disk ?? priceDisk
            priceCpu = prices.cpu ?? priceCpu
            priceSlot = prices.slots ?? priceSlot
        }
    }

    private func purchase() async {
        guard let tenant = session.currentTenant?.id else { return }
        let body: [String: Double] = ["memory": memory, "disk": disk, "cpu": cpu, "slots": slots]
        try? await session.api.postVoid("api/tenants/\(tenant)/store/purchase", body: body)
        await load()
    }
}
