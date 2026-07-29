import Testing
import Foundation
@testable import QuickBites
import QuickBitesCore

@Suite @MainActor struct OrdersViewModelTests {
    private func makeRepository() -> OrderRepository {
        OrderRepository(cache: CacheStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)))
    }

    @Test func loadWithNoOrdersShowsEmptyState() async {
        let viewModel = OrdersViewModel(repository: makeRepository())

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test func loadAfterCheckoutShowsOrder() async {
        let repository = makeRepository()
        await repository.setQty(mealId: "1", qty: 1, name: "Corba", priceInr: 150, thumbURL: nil)
        await repository.checkout()
        let viewModel = OrdersViewModel(repository: repository)

        await viewModel.load()

        guard case .content(let orders) = viewModel.state else {
            Issue.record("expected content")
            return
        }
        #expect(orders.count == 1)
    }
}
