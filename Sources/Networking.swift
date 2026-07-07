import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case http(Int, String)
    case decoding(String)
    case noResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid request URL."
        case .http(let code, let message):
            if code == 401 { return "Invalid credentials." }
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Server error (\(code))." : trimmed
        case .decoding(let detail): return "Unexpected server response. \(detail)"
        case .noResponse: return "No response from server."
        }
    }
}

/// Type-erased Encodable so we can pass any request body.
struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { encodeClosure = wrapped.encode }
    func encode(to encoder: Encoder) throws { try encodeClosure(encoder) }
}

/// Handles list endpoints that may return either a bare array or a paginated wrapper.
struct Paged<T: Decodable>: Decodable {
    let items: [T]?
    let data: [T]?
    let results: [T]?
    var values: [T] { items ?? data ?? results ?? [] }
}

final class APIClient {
    /// Base URL reverse-engineered from the original Android client.
    static let baseURLString = "https://hosting.altare.gg"

    var token: String?

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    private let decoder = JSONDecoder()

    private func makeRequest(_ path: String, method: String, body: Encodable?) throws -> URLRequest {
        guard let url = URL(string: "\(APIClient.baseURLString)/\(path)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }
        return request
    }

    @discardableResult
    func raw(_ path: String, method: String = "GET", body: Encodable? = nil) async throws -> Data {
        let request = try makeRequest(path, method: method, body: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.noResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        try decodeUnwrapping(try await raw(path))
    }

    @discardableResult
    func post<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        try decodeUnwrapping(try await raw(path, method: "POST", body: body))
    }

    func postVoid(_ path: String, body: Encodable? = nil) async throws {
        _ = try await raw(path, method: "POST", body: body)
    }

    func patchVoid(_ path: String, body: Encodable? = nil) async throws {
        _ = try await raw(path, method: "PATCH", body: body)
    }

    /// Decodes an object, transparently unwrapping a single well-known envelope
    /// key (data / user / attributes / ...) when the top level is wrapped.
    private func decodeUnwrapping<T: Decodable>(_ data: Data) throws -> T {
        if let direct = try? decoder.decode(T.self, from: data) { return direct }
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let keys = ["data", "user", "result", "tenant", "wallet", "rewards",
                        "resources", "account", "profile", "me", "attributes", "payload"]
            for key in keys {
                guard let inner = obj[key] else { continue }
                if let innerData = try? JSONSerialization.data(withJSONObject: inner, options: [.fragmentsAllowed]),
                   let decoded = try? decoder.decode(T.self, from: innerData) {
                    return decoded
                }
                if let innerObj = inner as? [String: Any],
                   let attrs = innerObj["attributes"],
                   let attrData = try? JSONSerialization.data(withJSONObject: attrs, options: [.fragmentsAllowed]),
                   let decoded = try? decoder.decode(T.self, from: attrData) {
                    return decoded
                }
            }
        }
        do { return try decoder.decode(T.self, from: data) }
        catch { throw APIError.decoding(String(describing: error)) }
    }

    /// Decodes list endpoints that may be bare arrays, paginated wrappers, or
    /// Pterodactyl-style { data: [ { attributes: {...} } ] } payloads.
    func getArray<T: Decodable>(_ path: String) async throws -> [T] {
        let data = try await raw(path)
        if let array = try? decoder.decode([T].self, from: data) { return array }
        if let paged = try? decoder.decode(Paged<T>.self, from: data) { return paged.values }
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let keys = ["data", "items", "results", "servers", "tenants", "values", "list", "nodes"]
            for key in keys {
                guard let innerArray = obj[key] as? [Any] else { continue }
                if let innerData = try? JSONSerialization.data(withJSONObject: innerArray),
                   let decoded = try? decoder.decode([T].self, from: innerData) {
                    return decoded
                }
                let mapped = innerArray.map { ($0 as? [String: Any])?["attributes"] ?? $0 }
                if let mappedData = try? JSONSerialization.data(withJSONObject: mapped),
                   let decoded = try? decoder.decode([T].self, from: mappedData) {
                    return decoded
                }
            }
        }
        return []
    }
}
