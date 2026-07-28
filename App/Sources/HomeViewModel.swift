import Foundation
import QuickBitesCore

@Observable
@MainActor
final class HomeViewModel {
    enum State: Equatable {
        case loading
        case content([MealCategory], bannerMessage: String?)
        case error(String)
    }

    private(set) var state: State = .loading
    private let repository: CatalogRepository

    init(repository: CatalogRepository) {
        self.repository = repository
    }

    func load() async {
        if case .content = state {
            // keep showing current content while a silent refresh runs
        } else {
            state = .loading
        }

        let (cached, refreshed) = await repository.categories()
        switch refreshed {
        case .success(let fresh):
            state = .content(fresh, bannerMessage: nil)
        case .failure:
            if let cached, !cached.isEmpty {
                state = .content(cached, bannerMessage: "Couldn't refresh — showing saved categories.")
            } else {
                state = .error("Couldn't load categories. Check your connection and try again.")
            }
        }
    }
}
