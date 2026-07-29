import Testing
import Foundation
@testable import QuickBites
import QuickBitesCore

@Suite @MainActor struct BrowseViewModelTests {
    private func makeCache() -> CacheStore {
        CacheStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
    }

    private static let mealsJSON = """
    { "meals": [ { "idMeal": "52977", "strMeal": "Corba", "strMealThumb": null } ] }
    """

    @Test func loadByCategoryPopulatesContent() async {
        let repository = CatalogRepository(client: MealDBClient(transport: FakeTransport.json(Self.mealsJSON)), cache: makeCache())
        let viewModel = BrowseViewModel(source: .category(id: "Vegetarian", name: "Vegetarian"), repository: repository)

        await viewModel.load()

        guard case .content(let meals, _) = viewModel.state else {
            Issue.record("expected content")
            return
        }
        #expect(meals.map(\.id) == ["52977"])
    }

    @Test func loadBySearchPopulatesContent() async {
        let repository = CatalogRepository(client: MealDBClient(transport: FakeTransport.json(Self.mealsJSON)), cache: makeCache())
        let viewModel = BrowseViewModel(source: .search(query: "corba"), repository: repository)

        await viewModel.load()

        guard case .content(let meals, _) = viewModel.state else {
            Issue.record("expected content")
            return
        }
        #expect(meals.map(\.id) == ["52977"])
    }

    @Test func loadWithNoResultsAndNoCacheShowsEmptyContent() async {
        let repository = CatalogRepository(client: MealDBClient(transport: FakeTransport.json(#"{ "meals": null }"#)), cache: makeCache())
        let viewModel = BrowseViewModel(source: .search(query: "nope"), repository: repository)

        await viewModel.load()

        guard case .content(let meals, _) = viewModel.state else {
            Issue.record("expected content")
            return
        }
        #expect(meals.isEmpty)
    }

    @Test func loadFallsBackToErrorWhenNoCacheAndNetworkFails() async {
        let repository = CatalogRepository(client: MealDBClient(transport: FakeTransport.failing()), cache: makeCache())
        let viewModel = BrowseViewModel(source: .search(query: "corba"), repository: repository)

        await viewModel.load()

        guard case .error = viewModel.state else {
            Issue.record("expected error")
            return
        }
    }
}
