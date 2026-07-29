import SwiftUI
import QuickBitesCore

struct BrowseView: View {
    @Environment(AppEnvironment.self) private var environment
    let title: String
    let source: BrowseViewModel.Source
    @State private var viewModel: BrowseViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(for: viewModel.state, viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(title)
        .task {
            if viewModel == nil {
                viewModel = BrowseViewModel(source: source, repository: environment.catalogRepository)
            }
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func content(for state: BrowseViewModel.State, viewModel: BrowseViewModel) -> some View {
        switch state {
        case .loading:
            ProgressView("Loading dishes…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .content(let meals, let bannerMessage):
            if meals.isEmpty {
                ContentUnavailableView("No dishes found", systemImage: "fork.knife")
            } else {
                List {
                    if let bannerMessage {
                        ErrorBanner(message: bannerMessage)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                    }
                    ForEach(meals) { meal in
                        NavigationLink(value: Route.detail(mealId: meal.id)) {
                            MealRow(meal: meal)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable { await viewModel.load() }
            }

        case .error(let message):
            ContentUnavailableView {
                Label("Something went wrong", systemImage: "wifi.slash")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") {
                    Task { await viewModel.load() }
                }
            }
        }
    }
}

private struct MealRow: View {
    let meal: MealSummary

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: meal.thumbURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.secondary.opacity(0.2)
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.body)
                Text("₹\(meal.priceInr)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
