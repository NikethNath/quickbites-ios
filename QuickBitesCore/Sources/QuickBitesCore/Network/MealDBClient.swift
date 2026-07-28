import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Synthetic price in INR for a meal id — must match the Android sibling exactly.
public func priceInr(mealId: String) -> Int {
    guard let n = Int64(mealId) else { return 99 }
    let hashed = n &* 2_654_435_761
    let nonnegativeMod = ((hashed % 401) + 401) % 401
    return 99 + Int(nonnegativeMod)
}

public struct MealDBClient: Sendable {
    private static let baseURL = URL(string: "https://www.themealdb.com/api/json/v1/1/")!

    private let transport: HTTPTransport

    public init(transport: HTTPTransport) {
        self.transport = transport
    }

    public func categories() async throws -> [MealCategory] {
        let url = Self.baseURL.appendingPathComponent("categories.php")
        let data = try await transport.get(url)
        let dto = try JSONDecoder().decode(CategoriesResponseDTO.self, from: data)
        return dto.categories.map { $0.toDomain() }
    }

    public func meals(inCategory category: String) async throws -> [MealSummary] {
        let url = try Self.url(path: "filter.php", queryItem: "c", value: category)
        let data = try await transport.get(url)
        let dto = try JSONDecoder().decode(MealsResponseDTO.self, from: data)
        return (dto.meals ?? []).map { $0.toDomain() }
    }

    public func search(query: String) async throws -> [MealSummary] {
        let url = try Self.url(path: "search.php", queryItem: "s", value: query)
        let data = try await transport.get(url)
        let dto = try JSONDecoder().decode(MealsResponseDTO.self, from: data)
        return (dto.meals ?? []).map { $0.toDomain() }
    }

    public func detail(id: String) async throws -> MealDetail? {
        let url = try Self.url(path: "lookup.php", queryItem: "i", value: id)
        let data = try await transport.get(url)
        let dto = try JSONDecoder().decode(MealDetailResponseDTO.self, from: data)
        return dto.meals?.first?.toDomain()
    }

    private static func url(path: String, queryItem: String, value: String) throws -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: queryItem, value: value)]
        guard let url = components?.url else { throw MealDBError.invalidURL }
        return url
    }
}
