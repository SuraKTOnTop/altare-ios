import SwiftUI

@MainActor
final class Session: ObservableObject {
    @Published var token: String? { didSet { persistToken() } }
    @Published var me: UserProfile?
    @Published var tenants: [Tenant] = []
    @Published var currentTenant: Tenant?

    let api = APIClient()
    private let tokenKey = "altare.auth.token"

    var isAuthenticated: Bool { token != nil }

    init() {
        let saved = UserDefaults.standard.string(forKey: tokenKey)
        token = saved
        api.token = saved
    }

    func bootstrap() async {
        guard token != nil else { return }
        await loadProfileAndTenants()
    }

    func login(identifier: String, password: String, capToken: String?) async throws {
        let response: AuthResponse = try await api.post(
            "api/auth/login",
            body: LoginRequest(identifier: identifier, password: password, capToken: capToken)
        )
        token = response.token
        api.token = response.token
        await loadProfileAndTenants()
    }

    func loadProfileAndTenants() async {
        // Fetch account, profile and tenants in parallel, then merge the two
        // profile sources so we fill in whatever each endpoint provides.
        async let accountResult: UserProfile? = try? await api.get("api/auth/account")
        async let meResult: UserProfile? = try? await api.get("api/user/me")
        async let tenantsResult: [Tenant] = (try? await api.getArray("api/tenants")) ?? []
        let (account, meProfile, loaded) = await (accountResult, meResult, tenantsResult)

        if let account {
            me = account.merged(with: meProfile)
        } else {
            me = meProfile
        }

        tenants = loaded
        if currentTenant == nil || !loaded.contains(where: { $0.id == currentTenant?.id }) {
            currentTenant = loaded.first
        }
    }

    func logout() {
        let path = "api/auth/logout"
        Task { [api] in try? await api.postVoid(path) }
        token = nil
        api.token = nil
        me = nil
        tenants = []
        currentTenant = nil
    }

    private func persistToken() {
        if let token {
            UserDefaults.standard.set(token, forKey: tokenKey)
        } else {
            UserDefaults.standard.removeObject(forKey: tokenKey)
        }
    }
}
