import Foundation

/// Actor-isolated JSON file cache — data-race safety by isolation, not locks.
/// Corrupt or missing files behave as a cache miss; callers never see a throw.
public actor CacheStore {
    private let directory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(directory: URL) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public func load<T: Decodable>(_ key: String) -> T? {
        guard let data = try? Data(contentsOf: fileURL(for: key)) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    public func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: fileURL(for: key), options: .atomic)
    }

    public func remove(_ key: String) {
        try? FileManager.default.removeItem(at: fileURL(for: key))
    }

    private func fileURL(for key: String) -> URL {
        directory.appendingPathComponent("\(key).json")
    }
}
