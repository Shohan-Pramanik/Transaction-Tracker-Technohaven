import Foundation

protocol PersistenceServiceProtocol: Sendable {
    func save<T: Codable & Sendable>(_ value: T, forKey key: String) throws
    func load<T: Codable & Sendable>(forKey key: String, as type: T.Type) throws -> T?
    func remove(forKey key: String)
}

enum PersistenceError: LocalizedError {
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to save data."
        case .decodingFailed:
            return "Failed to load data."
        }
    }
}

nonisolated final class PersistenceService: PersistenceServiceProtocol, @unchecked Sendable {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save<T: Codable & Sendable>(_ value: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value) else {
            throw PersistenceError.encodingFailed
        }
        defaults.set(data, forKey: key)
    }

    func load<T: Codable & Sendable>(forKey key: String, as type: T.Type) throws -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let value = try? decoder.decode(T.self, from: data) else {
            throw PersistenceError.decodingFailed
        }
        return value
    }

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
