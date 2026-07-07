import Foundation

/// A coding key that can represent any JSON property name.
struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.intValue = intValue; self.stringValue = String(intValue) }
}

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

    init(id: String? = nil, username: String? = nil, email: String? = nil) {
        self.id = id
        self.username = username
        self.email = email
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: DynamicKey.self)
        func str(_ keys: [String]) -> String? {
            for k in keys {
                guard let key = DynamicKey(stringValue: k) else { continue }
                if let s = try? c.decode(String.self, forKey: key), !s.isEmpty { return s }
                if let i = try? c.decode(Int.self, forKey: key) { return String(i) }
            }
            return nil
        }
        id = str(["id", "uuid", "userId", "user_id", "_id"])
        var name = str(["username", "userName", "user_name", "name", "displayName", "display_name", "handle", "nickname"])
        if name == nil {
            let first = str(["firstName", "first_name", "givenName"])
            let last = str(["lastName", "last_name", "familyName"])
            let combined = [first, last].compactMap { $0 }.joined(separator: " ")
            if !combined.isEmpty { name = combined }
        }
        username = name
        email = str(["email", "emailAddress", "email_address", "mail"])
    }

    /// Returns a copy where any nil field is filled from `other`.
    func merged(with other: UserProfile?) -> UserProfile {
        guard let other else { return self }
        return UserProfile(
            id: id ?? other.id,
            username: username ?? other.username,
            email: email ?? other.email
        )
    }
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

/// A single resource metric. Accepts either a bare number (treated as the
/// total/limit) or an object with used/total under many possible key names.
struct ResourceUsage: Decodable {
    let used: Double?
    let total: Double?

    init(used: Double? = nil, total: Double? = nil) {
        self.used = used
        self.total = total
    }

    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let v = try? single.decode(Double.self) {
            used = nil
            total = v
            return
        }
        let c = try decoder.container(keyedBy: DynamicKey.self)
        func num(_ keys: [String]) -> Double? {
            for k in keys {
                guard let key = DynamicKey(stringValue: k) else { continue }
                if let d = try? c.decode(Double.self, forKey: key) { return d }
                if let s = try? c.decode(String.self, forKey: key), let d = Double(s) { return d }
            }
            return nil
        }
        used = num(["used", "current", "usage", "consumed", "inUse", "allocated", "value"])
        total = num(["total", "limit", "max", "cap", "quota", "available", "amount"])
    }
}

/// Tenant resource summary. Tolerant of wrappers and of many key spellings.
struct TenantResources: Decodable {
    let memory: ResourceUsage?
    let disk: ResourceUsage?
    let cpu: ResourceUsage?
    let servers: ResourceUsage?

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: DynamicKey.self)
        var container = root
        for wrapper in ["resources", "limits", "usage", "data"] {
            if let key = DynamicKey(stringValue: wrapper),
               let nested = try? root.nestedContainer(keyedBy: DynamicKey.self, forKey: key) {
                container = nested
                break
            }
        }
        func usage(_ keys: [String]) -> ResourceUsage? {
            for k in keys {
                guard let key = DynamicKey(stringValue: k) else { continue }
                if let u = try? container.decode(ResourceUsage.self, forKey: key) { return u }
            }
            return nil
        }
        memory = usage(["memory", "ram", "mem"])
        disk = usage(["disk", "storage", "ssd", "diskSpace"])
        cpu = usage(["cpu", "cpuCores", "cores", "processor"])
        servers = usage(["servers", "serverSlots", "slots", "server_slots"])
    }
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
