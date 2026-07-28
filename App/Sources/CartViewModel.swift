import Foundation
import QuickBitesCore

@Observable
@MainActor
final class CartViewModel {
    enum State: Equatable {
        case loading
        case content([CartItem])
        case empty
    }

    private(set) var state: State = .loading
    private let repository: OrderRepository

    init(repository: OrderRepository) {
        self.repository = repository
    }

    var total: Int {
        guard case .content(let items) = state else { return 0 }
        return items.totalInr
    }

    func load() async {
        let items = await repository.cart()
        state = items.isEmpty ? .empty : .content(items)
    }

    func setQty(mealId: String, qty: Int, name: String, priceInr: Int, thumbURL: URL?) async {
        await repository.setQty(mealId: mealId, qty: qty, name: name, priceInr: priceInr, thumbURL: thumbURL)
        await load()
    }

    @discardableResult
    func checkout() async -> Bool {
        guard case .content = state else { return false }
        let order = await repository.checkout()
        await load()
        return order != nil
    }
}
