import Foundation
import QuickBitesCore

@Observable
final class AppEnvironment {
    let catalogRepository: CatalogRepository
    let orderRepository: OrderRepository

    init() {
        let cacheDirectory = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("QuickBitesCache", isDirectory: true)
        let cache = CacheStore(directory: cacheDirectory)
        catalogRepository = CatalogRepository(
            client: MealDBClient(transport: URLSessionTransport()),
            cache: cache
        )
        orderRepository = OrderRepository(cache: cache)
    }
}
