import Testing
import Foundation
@testable import QuickBitesCore

@Suite struct OrderRepositoryTests {
    private func makeDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    @Test func settingQtyAddsItemToCart() async {
        let repo = OrderRepository(cache: CacheStore(directory: makeDirectory()))

        let items = await repo.setQty(mealId: "52977", qty: 2, name: "Corba", priceInr: 150, thumbURL: nil)

        #expect(items == [CartItem(mealId: "52977", name: "Corba", thumbURL: nil, priceInr: 150, qty: 2)])
        let reread = await repo.cart()
        #expect(reread == items)
    }

    @Test func settingQtyToZeroRemovesItem() async {
        let repo = OrderRepository(cache: CacheStore(directory: makeDirectory()))
        await repo.setQty(mealId: "52977", qty: 2, name: "Corba", priceInr: 150, thumbURL: nil)

        let items = await repo.setQty(mealId: "52977", qty: 0, name: "Corba", priceInr: 150, thumbURL: nil)

        #expect(items.isEmpty)
        let reread = await repo.cart()
        #expect(reread.isEmpty)
    }

    @Test func checkoutMovesCartToOrdersAndClearsCart() async {
        let repo = OrderRepository(cache: CacheStore(directory: makeDirectory()))
        await repo.setQty(mealId: "52977", qty: 2, name: "Corba", priceInr: 150, thumbURL: nil)
        await repo.setQty(mealId: "53049", qty: 1, name: "Apam Balik", priceInr: 200, thumbURL: nil)

        let order = await repo.checkout()

        #expect(order != nil)
        #expect(order?.total == 2 * 150 + 1 * 200)
        #expect(order?.lines.count == 2)

        let cart = await repo.cart()
        #expect(cart.isEmpty)

        let orders = await repo.orders()
        #expect(orders.map(\.id) == [order?.id])
    }

    @Test func checkoutWithEmptyCartReturnsNilAndRecordsNothing() async {
        let repo = OrderRepository(cache: CacheStore(directory: makeDirectory()))

        let order = await repo.checkout()

        #expect(order == nil)
        let orders = await repo.orders()
        #expect(orders.isEmpty)
    }

    @Test func cartAndOrdersSurviveAcrossFreshCacheStoreInstances() async {
        let directory = makeDirectory()
        let firstLaunch = OrderRepository(cache: CacheStore(directory: directory))
        await firstLaunch.setQty(mealId: "52977", qty: 3, name: "Corba", priceInr: 150, thumbURL: nil)
        await firstLaunch.checkout()

        let secondLaunch = OrderRepository(cache: CacheStore(directory: directory))
        let orders = await secondLaunch.orders()
        let cart = await secondLaunch.cart()

        #expect(orders.count == 1)
        #expect(cart.isEmpty)
    }
}
