import Foundation

public struct Ingredient: Codable, Equatable, Sendable {
    public let name: String
    public let measure: String

    public init(name: String, measure: String) {
        self.name = name
        self.measure = measure
    }
}

public struct MealDetail: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let thumbURL: URL?
    public let priceInr: Int
    public let area: String?
    public let category: String?
    public let instructions: String?
    public let ingredients: [Ingredient]

    public init(
        id: String,
        name: String,
        thumbURL: URL?,
        priceInr: Int,
        area: String?,
        category: String?,
        instructions: String?,
        ingredients: [Ingredient]
    ) {
        self.id = id
        self.name = name
        self.thumbURL = thumbURL
        self.priceInr = priceInr
        self.area = area
        self.category = category
        self.instructions = instructions
        self.ingredients = ingredients
    }
}
