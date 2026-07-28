import Testing
import Foundation
@testable import QuickBitesCore

@Suite struct CartTests {
    @Test func totalInrSumsPriceTimesQtyAcrossLines() {
        let items = [
            CartItem(mealId: "1", name: "Corba", thumbURL: nil, priceInr: 150, qty: 2),
            CartItem(mealId: "2", name: "Apam Balik", thumbURL: nil, priceInr: 200, qty: 1),
        ]

        #expect(items.totalInr == 2 * 150 + 1 * 200)
    }

    @Test func totalInrOfEmptyCartIsZero() {
        let items: [CartItem] = []
        #expect(items.totalInr == 0)
    }
}
