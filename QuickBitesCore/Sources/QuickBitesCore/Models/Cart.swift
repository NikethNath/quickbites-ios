import Foundation

public struct CartItem: Codable, Equatable, Sendable, Identifiable {
    public var id: String { mealId }
    public let mealId: String
    public let name: String
    public let thumbURL: URL?
    public let priceInr: Int
    public let qty: Int

    public init(mealId: String, name: String, thumbURL: URL?, priceInr: Int, qty: Int) {
        self.mealId = mealId
        self.name = name
        self.thumbURL = thumbURL
        self.priceInr = priceInr
        self.qty = qty
    }
}
