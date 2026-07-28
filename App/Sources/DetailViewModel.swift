import Foundation
import QuickBitesCore

@Observable
@MainActor
final class DetailViewModel {
    enum State: Equatable {
        case loading
        case content(MealDetail, bannerMessage: String?)
        case error(String)
    }

    private(set) var state: State = .loading
    private(set) var qtyInCart = 0

    private let mealId: String
    private let catalogRepository: CatalogRepository
    private let orderRepository: OrderRepository

    init(mealId: String, catalogRepository: CatalogRepository, orderRepository: OrderRepository) {
        self.mealId = mealId
        self.catalogRepository = catalogRepository
        self.orderRepository = orderRepository
    }

    func load() async {
        if case .content = state {
            // keep showing current content while a silent refresh runs
        } else {
            state = .loading
        }

        async let detailCall = catalogRepository.detail(id: mealId)
        async let cartCall = orderRepository.cart()

        let (cached, refreshed) = await detailCall
        qtyInCart = await cartCall.first(where: { $0.mealId == mealId })?.qty ?? 0

        switch refreshed {
        case .success(let fresh):
            if let fresh {
                state = .content(fresh, bannerMessage: nil)
            } else if let cached {
                state = .content(cached, bannerMessage: "This dish is no longer listed.")
            } else {
                state = .error("Dish not found.")
            }
        case .failure:
            if let cached {
                state = .content(cached, bannerMessage: "Couldn't refresh — showing saved details.")
            } else {
                state = .error("Couldn't load this dish. Check your connection and try again.")
            }
        }
    }

    func setQty(_ qty: Int) async {
        guard case .content(let meal, _) = state else { return }
        qtyInCart = max(0, qty)
        await orderRepository.setQty(
            mealId: meal.id,
            qty: qtyInCart,
            name: meal.name,
            priceInr: meal.priceInr,
            thumbURL: meal.thumbURL
        )
    }

    func addToCart() async {
        await setQty(qtyInCart + 1)
    }
}
