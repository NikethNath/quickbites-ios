import SwiftUI

struct RootView: View {
    @State private var homePath = NavigationPath()

    var body: some View {
        TabView {
            NavigationStack(path: $homePath) {
                HomeView(path: $homePath)
                    .navigationDestination(for: Route.self, destination: routeDestination)
            }
            .tabItem { Label("Home", systemImage: "house") }

            NavigationStack {
                CartView()
                    .navigationDestination(for: Route.self, destination: routeDestination)
            }
            .tabItem { Label("Cart", systemImage: "cart") }

            NavigationStack {
                OrdersView()
                    .navigationDestination(for: Route.self, destination: routeDestination)
            }
            .tabItem { Label("Orders", systemImage: "list.bullet.rectangle") }
        }
    }

    @ViewBuilder
    private func routeDestination(for route: Route) -> some View {
        switch route {
        case .browseCategory(_, let name):
            BrowseView(title: name)
        case .browseSearch(let query):
            BrowseView(title: "Search results for \"\(query)\"")
        case .detail(let mealId):
            DetailView(mealId: mealId)
        }
    }
}
