import Foundation
import QuickBitesCore

@Observable
@MainActor
final class BrowseViewModel {
    enum Source {
        case category(id: String, name: String)
        case search(query: String)
    }

    enum State: Equatable {
        case loading
        case content([MealSummary], bannerMessage: String?)
        case error(String)
    }

    private(set) var state: State = .loading
    private let source: Source
    private let repository: CatalogRepository

    init(source: Source, repository: CatalogRepository) {
        self.source = source
        self.repository = repository
    }

    func load() async {
        if case .content = state {
            // keep showing current content while a silent refresh runs
        } else {
            state = .loading
        }

        let cached: [MealSummary]?
        let refreshed: Result<[MealSummary], Error>
        switch source {
        case .category(let id, _):
            (cached, refreshed) = await repository.mealsFor(category: id)
        case .search(let query):
            (cached, refreshed) = await repository.search(query: query)
        }

        switch refreshed {
        case .success(let fresh):
            state = .content(fresh, bannerMessage: nil)
        case .failure:
            if let cached, !cached.isEmpty {
                state = .content(cached, bannerMessage: "Couldn't refresh — showing saved results.")
            } else {
                state = .error("Couldn't load dishes. Check your connection and try again.")
            }
        }
    }
}
