import SwiftUI

enum Tab: Hashable {
    case home, cart, orders
}

struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var homePath = NavigationPath()
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $homePath) {
                HomeView(path: $homePath)
                    .navigationDestination(for: Route.self, destination: routeDestination)
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(Tab.home)

            NavigationStack {
                CartView(selectedTab: $selectedTab)
                    .navigationDestination(for: Route.self, destination: routeDestination)
            }
            .tabItem { Label("Cart", systemImage: "cart") }
            .tag(Tab.cart)
            .badge(environment.cartCount)

            NavigationStack {
                OrdersView()
                    .navigationDestination(for: Route.self, destination: routeDestination)
            }
            .tabItem { Label("Orders", systemImage: "list.bullet.rectangle") }
            .tag(Tab.orders)
        }
        .task {
            await environment.refreshCartCount()
            applyScreenshotLaunchArgumentsIfPresent()
        }
    }

    /// Lets CI's screenshot job (`xcrun simctl launch` with `SIMCTL_CHILD_`-prefixed
    /// env vars) land directly on a specific screen without UI scripting.
    private func applyScreenshotLaunchArgumentsIfPresent() {
        let env = ProcessInfo.processInfo.environment
        switch env["QB_SCREENSHOT_TAB"] {
        case "cart": selectedTab = .cart
        case "orders": selectedTab = .orders
        default: break
        }
        if let mealId = env["QB_SCREENSHOT_DETAIL_MEAL_ID"] {
            homePath.append(Route.detail(mealId: mealId))
        }
    }

    @ViewBuilder
    private func routeDestination(for route: Route) -> some View {
        switch route {
        case .browseCategory(let id, let name):
            BrowseView(title: name, source: .category(id: id, name: name))
        case .browseSearch(let query):
            BrowseView(title: "Search results for \"\(query)\"", source: .search(query: query))
        case .detail(let mealId):
            DetailView(mealId: mealId)
        }
    }
}
