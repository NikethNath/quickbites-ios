import Foundation

/// Cart CRUD and mock checkout, all through `CacheStore` so state survives relaunch.
public struct OrderRepository: Sendable {
    private let cache: CacheStore

    public init(cache: CacheStore) {
        self.cache = cache
    }

    public func cart() async -> [CartItem] {
        await cache.load(Keys.cart) ?? []
    }

    /// Upserts the line for `mealId`; `qty <= 0` removes it.
    @discardableResult
    public func setQty(mealId: String, qty: Int, name: String, priceInr: Int, thumbURL: URL?) async -> [CartItem] {
        var items = await cart()
        items.removeAll { $0.mealId == mealId }
        if qty > 0 {
            items.append(CartItem(mealId: mealId, name: name, thumbURL: thumbURL, priceInr: priceInr, qty: qty))
        }
        await cache.save(items, key: Keys.cart)
        return items
    }

    public func orders() async -> [Order] {
        await cache.load(Keys.orders) ?? []
    }

    /// Builds an `Order` from the current cart, appends it to order history,
    /// and clears the cart — `nil` if the cart is empty.
    @discardableResult
    public func checkout() async -> Order? {
        let items = await cart()
        guard !items.isEmpty else { return nil }

        let lines = items.map { OrderLine(mealId: $0.mealId, name: $0.name, priceInr: $0.priceInr, qty: $0.qty) }
        let total = lines.reduce(0) { $0 + $1.priceInr * $1.qty }
        let order = Order(id: UUID(), placedAt: Date(), total: total, lines: lines)

        var history = await orders()
        history.insert(order, at: 0)
        await cache.save(history, key: Keys.orders)
        await cache.save([CartItem](), key: Keys.cart)
        return order
    }

    private enum Keys {
        static let cart = "cart"
        static let orders = "orders"
    }
}
