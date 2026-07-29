import Testing
import Foundation
@testable import QuickBites
import QuickBitesCore

@Suite @MainActor struct DetailViewModelTests {
    private static let detailJSON = """
    { "meals": [
        {
          "idMeal": "52977",
          "strMeal": "Corba",
          "strMealThumb": null,
          "strArea": "Turkish",
          "strCategory": "Vegetarian",
          "strInstructions": "Boil the lentils.",
          "strIngredient1": "Lentils",
          "strMeasure1": "1 cup"
        }
    ] }
    """

    private func makeRepositories(transport: HTTPTransport) -> (catalog: CatalogRepository, orders: OrderRepository) {
        let cache = CacheStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        return (
            CatalogRepository(client: MealDBClient(transport: transport), cache: cache),
            OrderRepository(cache: cache)
        )
    }

    @Test func loadPopulatesDetailAndZeroQtyWhenNotInCart() async {
        let repositories = makeRepositories(transport: FakeTransport.json(Self.detailJSON))
        let viewModel = DetailViewModel(mealId: "52977", catalogRepository: repositories.catalog, orderRepository: repositories.orders)

        await viewModel.load()

        guard case .content(let meal, _) = viewModel.state else {
            Issue.record("expected content")
            return
        }
        #expect(meal.id == "52977")
        #expect(viewModel.qtyInCart == 0)
    }

    @Test func addToCartIncrementsQtyAndPersists() async {
        let repositories = makeRepositories(transport: FakeTransport.json(Self.detailJSON))
        let viewModel = DetailViewModel(mealId: "52977", catalogRepository: repositories.catalog, orderRepository: repositories.orders)
        await viewModel.load()

        await viewModel.addToCart()

        #expect(viewModel.qtyInCart == 1)
        let cart = await repositories.orders.cart()
        #expect(cart.first?.qty == 1)
    }

    @Test func setQtyToZeroRemovesFromCart() async {
        let repositories = makeRepositories(transport: FakeTransport.json(Self.detailJSON))
        let viewModel = DetailViewModel(mealId: "52977", catalogRepository: repositories.catalog, orderRepository: repositories.orders)
        await viewModel.load()
        await viewModel.addToCart()

        await viewModel.setQty(0)

        #expect(viewModel.qtyInCart == 0)
        let cart = await repositories.orders.cart()
        #expect(cart.isEmpty)
    }
}
