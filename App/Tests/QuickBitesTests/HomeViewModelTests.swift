import Testing
import Foundation
@testable import QuickBites
import QuickBitesCore

@Suite @MainActor struct HomeViewModelTests {
    private func makeCache() -> CacheStore {
        CacheStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
    }

    @Test func startsInLoadingState() {
        let repository = CatalogRepository(client: MealDBClient(transport: FakeTransport.json(#"{ "categories": [] }"#)), cache: makeCache())
        let viewModel = HomeViewModel(repository: repository)

        #expect(viewModel.state == .loading)
    }

    @Test func loadPopulatesContentOnSuccess() async {
        let json = """
        { "categories": [ { "idCategory": "1", "strCategory": "Beef", "strCategoryThumb": null } ] }
        """
        let repository = CatalogRepository(client: MealDBClient(transport: FakeTransport.json(json)), cache: makeCache())
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.load()

        guard case .content(let categories, let banner) = viewModel.state else {
            Issue.record("expected content")
            return
        }
        #expect(categories.map(\.id) == ["1"])
        #expect(banner == nil)
    }

    @Test func loadFallsBackToErrorWhenNoCacheAndNetworkFails() async {
        let repository = CatalogRepository(client: MealDBClient(transport: FakeTransport.failing()), cache: makeCache())
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.load()

        guard case .error = viewModel.state else {
            Issue.record("expected error")
            return
        }
    }

    @Test func loadShowsCachedDataWithBannerWhenNetworkFails() async {
        let cache = makeCache()
        await cache.save([MealCategory(id: "1", name: "Beef", thumbURL: nil)], key: "categories")
        let repository = CatalogRepository(client: MealDBClient(transport: FakeTransport.failing()), cache: cache)
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.load()

        guard case .content(let categories, let banner) = viewModel.state else {
            Issue.record("expected content")
            return
        }
        #expect(categories.map(\.id) == ["1"])
        #expect(banner != nil)
    }
}
