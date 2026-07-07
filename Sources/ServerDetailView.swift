import SwiftUI

struct ServerDetailView: View {
    @EnvironmentObject var session: Session
    let serverId: String

    @State private var server: Server?
    @State private var selectedTab = 0
    @State private var command = ""
    @State private var consoleLines: [String] = []
    private let tabs = ["Console", "Files", "Backups", "Startup"]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    powerButtons
                    statsRow
                    tabPicker
                    tabContent
                }
                .padding(16)
            }
        }
        .navigationTitle(server?.name ?? "Server")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let status = server?.displayStatus { StatusBadge(status: status) }
            }
        }
        .task { await load() }
    }

    // MARK: Power

    private var powerButtons: some View {
        HStack(spacing: 10) {
            powerButton("Start", "play.fill", Theme.green) { await power("start") }
            powerButton("Restart", "arrow.clockwise", nil) { await power("restart") }
            powerButton("Stop", "stop.fill", nil) { await power("stop") }
            powerButton("Kill", "exclamationmark.triangle.fill", Theme.red) { await power("kill") }
        }
    }

    private func powerButton(_ title: String, _ icon: String, _ tint: Color?, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(tint ?? .white)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatBox(value: "0.0%", label: "CPU")
            StatBox(value: Format.gb(server?.limits?.memory), label: "Memory")
            StatBox(value: "\u{2014}", label: "Uptime")
        }
    }

    // MARK: Tabs

    private var tabPicker: some View {
        HStack(spacing: 20) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, title in
                Button {
                    selectedTab = index
                } label: {
                    VStack(spacing: 6) {
                        Text(title)
                            .font(.subheadline.weight(selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? .white : Theme.textSecondary)
                        Rectangle()
                            .fill(selectedTab == index ? Color.white : Color.clear)
                            .frame(height: 2)
                    }
                }
            }
            Spacer()
        }
    }

    @ViewBuilder private var tabContent: some View {
        switch selectedTab {
        case 0: consoleView
        default:
            Text("\(tabs[selectedTab]) are managed on the web dashboard.")
                .font(.footnote)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 24)
        }
    }

    private var consoleView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Theme.green).frame(width: 7, height: 7)
                    Text("Live").font(.caption).foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Button("Clear") { consoleLines.removeAll() }
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(consoleLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(height: 240)
            .padding(10)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                TextField("Enter a command", text: $command)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button {
                    Task { await sendCommand() }
                } label: {
                    Image(systemName: "paperplane.fill").foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.field)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: Actions

    private func load() async {
        guard let tenant = session.currentTenant?.id else { return }
        server = try? await session.api.get("api/tenants/\(tenant)/servers/\(serverId)") as Server
    }

    private func power(_ signal: String) async {
        consoleLines.append("[panel] sending power signal: \(signal)")
        try? await session.api.postVoid(
            "api/core/control/servers/\(serverId)/power",
            body: ["signal": signal]
        )
    }

    private func sendCommand() async {
        let trimmed = command.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        consoleLines.append("> \(trimmed)")
        command = ""
        try? await session.api.postVoid(
            "api/core/control/servers/\(serverId)/command",
            body: ["command": trimmed]
        )
    }
}
