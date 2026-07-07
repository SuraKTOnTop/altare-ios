import Foundation

/// Accepts an id that the backend may encode as either a String or a number.
struct AnyID: Codable, Hashable {
    let value: String
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) { value = string }
        else if let int = try? container.decode(Int.self) { value = String(int) }
        else if let double = try? container.decode(Double.self) { value = String(Int(double)) }
        else { value = UUID().uuidString }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - Auth

struct LoginRequest: Encodable {
    let identifier: String
    let password: String
    let capToken: String?
}

struct AuthResponse: Decodable { let token: String }

// MARK: - User / Tenant

struct UserProfile: Decodable {
    let id: String?
    let username: String?
    let email: String?
}

struct Tenant: Decodable, Identifiable, Hashable {
    private let _id: AnyID
    let name: String?
    let role: String?
    var id: String { _id.value }

    enum CodingKeys: String, CodingKey {
        case _id = "id"
        case name, role
    }
}

struct ResourceUsage: Decodable {
    let used: Double?
    let total: Double?
}

struct TenantResources: Decodable {
    let memory: ResourceUsage?
    let disk: ResourceUsage?
    let cpu: ResourceUsage?
    let servers: ResourceUsage?
}

// MARK: - Servers

struct ServerLimits: Decodable {
    let memory: Double?
    let disk: Double?
    let cpu: Double?
}

struct Server: Decodable, Identifiable {
    private let _id: AnyID
    let uuid: String?
    let name: String?
    let status: String?
    let state: String?
    let node: String?
    let location: String?
    let limits: ServerLimits?

    var id: String { _id.value }
    var displayStatus: String { status ?? state ?? "unknown" }

    enum CodingKeys: String, CodingKey {
        case _id = "id"
        case uuid, name, status, state, node, location, limits
    }
}

// MARK: - Wallet

struct WalletInfo: Decodable {
    let balance: Double?
    let credits: Double?
    var amount: Double { balance ?? credits ?? 0 }
}

struct StorePrices: Decodable {
    let memory: Double?
    let disk: Double?
    let cpu: Double?
    let slots: Double?
}

// MARK: - Rewards

struct DailyReward: Decodable {
    let reward: Double?
    let streak: Int?
    let nextStreak: Int?
}

struct AfkInfo: Decodable {
    let now: Double?
    let perMinute: Double?
    let party: Double?
    let earning: Bool?
}

struct ReferralInfo: Decodable {
    let code: String?
}

struct RewardsInfo: Decodable {
    let daily: DailyReward?
    let afk: AfkInfo?
    let referral: ReferralInfo?
}
