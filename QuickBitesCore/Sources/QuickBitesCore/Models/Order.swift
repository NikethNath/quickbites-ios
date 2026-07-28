import Foundation

public struct OrderLine: Codable, Equatable, Sendable {
    public let mealId: String
    public let name: String
    public let priceInr: Int
    public let qty: Int

    public init(mealId: String, name: String, priceInr: Int, qty: Int) {
        self.mealId = mealId
        self.name = name
        self.priceInr = priceInr
        self.qty = qty
    }
}

public struct Order: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let placedAt: Date
    public let total: Int
    public let lines: [OrderLine]

    public init(id: UUID, placedAt: Date, total: Int, lines: [OrderLine]) {
        self.id = id
        self.placedAt = placedAt
        self.total = total
        self.lines = lines
    }
}
