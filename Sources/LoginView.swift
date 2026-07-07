import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: Session
    @EnvironmentObject var settings: AppSettings
    @State private var identifier = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var loading = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 14) {
                Spacer()

                Image("Logo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(Theme.accent)

                Text("Altare")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text(settings.t("signInSubtitle"))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.bottom, 14)

                field(icon: "person", placeholder: settings.t("emailOrUsername"), text: $identifier, secure: false)
                field(icon: "lock.fill", placeholder: settings.t("password"), text: $password, secure: true)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(Theme.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(
                    title: loading ? settings.t("signingIn") : settings.t("signIn"),
                    enabled: !loading && !identifier.isEmpty && !password.isEmpty
                ) {
                    Task { await signIn() }
                }
                .padding(.top, 4)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 26)
        }
    }

    private func field(icon: String, placeholder: String, text: Binding<String>, secure: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.textSecondary)
                .frame(width: 20)
            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                }
            }
            .foregroundColor(Theme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Theme.field)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func signIn() async {
        loading = true
        errorMessage = nil
        do {
            try await session.login(identifier: identifier, password: password, capToken: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }
}
