import SwiftUI
import QuickBitesCore

struct HomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @Binding var path: NavigationPath
    @State private var viewModel: HomeViewModel?
    @State private var searchText = ""

    var body: some View {
        Group {
            if let viewModel {
                content(for: viewModel.state, viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("QuickBites")
        .searchable(text: $searchText, prompt: "Search dishes")
        .onSubmit(of: .search) {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return }
            path.append(Route.browseSearch(query: query))
        }
        .task {
            if viewModel == nil {
                viewModel = HomeViewModel(repository: environment.catalogRepository)
            }
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func content(for state: HomeViewModel.State, viewModel: HomeViewModel) -> some View {
        switch state {
        case .loading:
            ProgressView("Loading categories…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .content(let categories, let bannerMessage):
            ScrollView {
                VStack(spacing: 12) {
                    if let bannerMessage {
                        ErrorBanner(message: bannerMessage)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                        ForEach(categories) { category in
                            NavigationLink(value: Route.browseCategory(id: category.id, name: category.name)) {
                                CategoryCell(category: category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .refreshable { await viewModel.load() }

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

private struct CategoryCell: View {
    let category: MealCategory

    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: category.thumbURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.secondary.opacity(0.2)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityHidden(true)

            Text(category.name)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .combine)
    }
}
