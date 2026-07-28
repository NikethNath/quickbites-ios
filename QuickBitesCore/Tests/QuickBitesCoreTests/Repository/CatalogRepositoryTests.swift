import Testing
import Foundation
@testable import QuickBitesCore

@Suite struct CatalogRepositoryTests {
    private func makeCache() -> CacheStore {
        CacheStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
    }

    private static let categoriesJSON = """
    { "categories": [ { "idCategory": "1", "strCategory": "Beef", "strCategoryThumb": null } ] }
    """
    private static let updatedCategoriesJSON = """
    { "categories": [
        { "idCategory": "1", "strCategory": "Beef", "strCategoryThumb": null },
        { "idCategory": "2", "strCategory": "Chicken", "strCategoryThumb": null }
    ] }
    """

    @Test func coldStartHasNoCacheAndNetworkPopulatesIt() async {
        let cache = makeCache()
        let repo = CatalogRepository(client: MealDBClient(transport: FakeTransport.json(Self.categoriesJSON)), cache: cache)

        let (cached, refreshed) = await repo.categories()

        #expect(cached == nil)
        guard case .success(let fresh) = refreshed else {
            Issue.record("expected success")
            return
        }
        #expect(fresh.map(\.id) == ["1"])

        let (secondCached, _) = await repo.categories()
        #expect(secondCached?.map(\.id) == ["1"])
    }

    @Test func warmStartReturnsCachedThenRefreshes() async {
        let cache = makeCache()
        await cache.save(
            [MealCategory(id: "1", name: "Beef", thumbURL: nil)],
            key: "categories"
        )
        let repo = CatalogRepository(client: MealDBClient(transport: FakeTransport.json(Self.updatedCategoriesJSON)), cache: cache)

        let (cached, refreshed) = await repo.categories()

        #expect(cached?.map(\.id) == ["1"])
        guard case .success(let fresh) = refreshed else {
            Issue.record("expected success")
            return
        }
        #expect(fresh.map(\.id) == ["1", "2"])

        let (secondCached, _) = await repo.categories()
        #expect(secondCached?.map(\.id) == ["1", "2"])
    }

    @Test func networkFailureKeepsCachedDataAndReportsFailure() async {
        let cache = makeCache()
        await cache.save(
            [MealCategory(id: "1", name: "Beef", thumbURL: nil)],
            key: "categories"
        )
        let repo = CatalogRepository(client: MealDBClient(transport: FakeTransport.failing()), cache: cache)

        let (cached, refreshed) = await repo.categories()

        #expect(cached?.map(\.id) == ["1"])
        guard case .failure = refreshed else {
            Issue.record("expected failure")
            return
        }

        let (stillCached, _) = await repo.categories()
        #expect(stillCached?.map(\.id) == ["1"])
    }

    @Test func mealsForCategoryPopulatesItsOwnCacheKey() async {
        let cache = makeCache()
        let json = """
        { "meals": [ { "idMeal": "52977", "strMeal": "Corba", "strMealThumb": null } ] }
        """
        let repo = CatalogRepository(client: MealDBClient(transport: FakeTransport.json(json)), cache: cache)

        let (cached, refreshed) = await repo.mealsFor(category: "Vegetarian")

        #expect(cached == nil)
        guard case .success(let fresh) = refreshed else {
            Issue.record("expected success")
            return
        }
        #expect(fresh.map(\.id) == ["52977"])
    }

    @Test func detailReturningNilDoesNotCrashOrOverwriteCache() async {
        let cache = makeCache()
        let repo = CatalogRepository(client: MealDBClient(transport: FakeTransport.json(#"{ "meals": null }"#)), cache: cache)

        let (cached, refreshed) = await repo.detail(id: "0")

        #expect(cached == nil)
        guard case .success(let fresh) = refreshed else {
            Issue.record("expected success")
            return
        }
        #expect(fresh == nil)
    }
}
