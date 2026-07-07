import SwiftUI

struct ServerDetailView: View {
    @EnvironmentObject var session: Session
    @EnvironmentObject var settings: AppSettings
    let serverId: String

    @State private var server: Server?
    @State private var selectedTab = 0
    @State private var command = ""
    @State private var consoleLines: [String] = []

    private var tabs: [String] {
        [settings.t("console"), settings.t("files"), settings.t("backups"), settings.t("startup")]
    }

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
        .navigationTitle(server?.name ?? settings.t("server"))
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
            powerButton(settings.t("start"), "play.fill", Theme.green) { await power("start") }
            powerButton(settings.t("restart"), "arrow.clockwise", nil) { await power("restart") }
            powerButton(settings.t("stop"), "stop.fill", nil) { await power("stop") }
            powerButton(settings.t("kill"), "exclamationmark.triangle.fill", Theme.red) { await power("kill") }
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
            .foregroundColor(.white)
            .glass(cornerRadius: 14, tint: tint ?? Theme.accent)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatBox(value: "0.0%", label: settings.t("cpu"))
            StatBox(value: Format.gb(server?.limits?.memory), label: settings.t("memory"))
            StatBox(value: "—", label: settings.t("uptime"))
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
                            .foregroundColor(selectedTab == index ? Theme.textPrimary : Theme.textSecondary)
                        Rectangle()
                            .fill(selectedTab == index ? Theme.accent : Color.clear)
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
            Text(String(format: settings.t("webManagedFmt"), tabs[selectedTab]))
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
                    Text(settings.t("live")).font(.caption).foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Button(settings.t("clear")) { consoleLines.removeAll() }
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(consoleLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Theme.textPrimary.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(height: 240)
            .padding(10)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                TextField(settings.t("enterCommand"), text: $command)
                    .foregroundColor(Theme.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button {
                    Task { await sendCommand() }
                } label: {
                    Image(systemName: "paperplane.fill").foregroundColor(Theme.accent)
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
