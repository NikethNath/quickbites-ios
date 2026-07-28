import Foundation
import QuickBitesCore

@Observable
@MainActor
final class OrdersViewModel {
    enum State: Equatable {
        case loading
        case content([Order])
        case empty
    }

    private(set) var state: State = .loading
    private let repository: OrderRepository

    init(repository: OrderRepository) {
        self.repository = repository
    }

    func load() async {
        let orders = await repository.orders()
        state = orders.isEmpty ? .empty : .content(orders)
    }
}
