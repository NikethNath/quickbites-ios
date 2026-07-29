import Testing
import Foundation
@testable import QuickBites
import QuickBitesCore

@Suite @MainActor struct CartViewModelTests {
    private func makeRepository() -> OrderRepository {
        OrderRepository(cache: CacheStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)))
    }

    @Test func loadWithEmptyCartShowsEmptyState() async {
        let viewModel = CartViewModel(repository: makeRepository())

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test func loadWithItemsShowsContentAndTotal() async {
        let repository = makeRepository()
        await repository.setQty(mealId: "1", qty: 2, name: "Corba", priceInr: 150, thumbURL: nil)
        let viewModel = CartViewModel(repository: repository)

        await viewModel.load()

        guard case .content(let items) = viewModel.state else {
            Issue.record("expected content")
            return
        }
        #expect(items.count == 1)
        #expect(viewModel.total == 300)
    }

    @Test func checkoutClearsCartAndReturnsTrue() async {
        let repository = makeRepository()
        await repository.setQty(mealId: "1", qty: 2, name: "Corba", priceInr: 150, thumbURL: nil)
        let viewModel = CartViewModel(repository: repository)
        await viewModel.load()

        let success = await viewModel.checkout()

        #expect(success)
        #expect(viewModel.state == .empty)
        let orders = await repository.orders()
        #expect(orders.count == 1)
    }

    @Test func checkoutWithEmptyCartReturnsFalse() async {
        let viewModel = CartViewModel(repository: makeRepository())
        await viewModel.load()

        let success = await viewModel.checkout()

        #expect(success == false)
    }
}
