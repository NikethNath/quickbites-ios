import Foundation

public struct MealCategory: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let thumbURL: URL?

    public init(id: String, name: String, thumbURL: URL?) {
        self.id = id
        self.name = name
        self.thumbURL = thumbURL
    }
}
