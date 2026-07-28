import Foundation

public protocol HTTPTransport: Sendable {
    func get(_ url: URL) async throws -> Data
}

public enum MealDBError: Error, Equatable, Sendable {
    case badResponse
    case invalidURL
}
