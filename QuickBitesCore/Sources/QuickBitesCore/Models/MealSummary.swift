import Foundation

public struct MealSummary: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let thumbURL: URL?
    public let priceInr: Int

    public init(id: String, name: String, thumbURL: URL?, priceInr: Int) {
        self.id = id
        self.name = name
        self.thumbURL = thumbURL
        self.priceInr = priceInr
    }
}
