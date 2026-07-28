import Foundation

/// Offline-first reads: cached data returns immediately, a network refresh
/// writes through the cache, and failures surface as `Result` while the
/// cached value keeps rendering.
public struct CatalogRepository: Sendable {
    private let client: MealDBClient
    private let cache: CacheStore

    public init(client: MealDBClient, cache: CacheStore) {
        self.client = client
        self.cache = cache
    }

    public func categories() async -> (cached: [MealCategory]?, refreshed: Result<[MealCategory], Error>) {
        let key = Keys.categories
        let cached: [MealCategory]? = await cache.load(key)
        do {
            let fresh = try await client.categories()
            await cache.save(fresh, key: key)
            return (cached, .success(fresh))
        } catch {
            return (cached, .failure(error))
        }
    }

    public func mealsFor(category: String) async -> (cached: [MealSummary]?, refreshed: Result<[MealSummary], Error>) {
        let key = Keys.meals(category: category)
        let cached: [MealSummary]? = await cache.load(key)
        do {
            let fresh = try await client.meals(inCategory: category)
            await cache.save(fresh, key: key)
            return (cached, .success(fresh))
        } catch {
            return (cached, .failure(error))
        }
    }

    public func search(query: String) async -> (cached: [MealSummary]?, refreshed: Result<[MealSummary], Error>) {
        let key = Keys.search(query: query)
        let cached: [MealSummary]? = await cache.load(key)
        do {
            let fresh = try await client.search(query: query)
            await cache.save(fresh, key: key)
            return (cached, .success(fresh))
        } catch {
            return (cached, .failure(error))
        }
    }

    public func detail(id: String) async -> (cached: MealDetail?, refreshed: Result<MealDetail?, Error>) {
        let key = Keys.detail(id: id)
        let cached: MealDetail? = await cache.load(key)
        do {
            let fresh = try await client.detail(id: id)
            if let fresh {
                await cache.save(fresh, key: key)
            }
            return (cached, .success(fresh))
        } catch {
            return (cached, .failure(error))
        }
    }

    private enum Keys {
        static let categories = "categories"
        static func meals(category: String) -> String { "meals-category-\(category)" }
        static func search(query: String) -> String { "meals-search-\(query)" }
        static func detail(id: String) -> String { "meal-detail-\(id)" }
    }
}
