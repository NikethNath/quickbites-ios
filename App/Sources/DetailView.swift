import SwiftUI
import QuickBitesCore

struct DetailView: View {
    @Environment(AppEnvironment.self) private var environment
    let mealId: String
    @State private var viewModel: DetailViewModel?
    @State private var instructionsExpanded = false

    var body: some View {
        Group {
            if let viewModel {
                content(for: viewModel.state, viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Dish")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = DetailViewModel(
                    mealId: mealId,
                    catalogRepository: environment.catalogRepository,
                    orderRepository: environment.orderRepository
                )
            }
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func content(for state: DetailViewModel.State, viewModel: DetailViewModel) -> some View {
        switch state {
        case .loading:
            ProgressView("Loading dish…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .content(let meal, let bannerMessage):
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let bannerMessage {
                        ErrorBanner(message: bannerMessage)
                    }

                    AsyncImage(url: meal.thumbURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.secondary.opacity(0.2)
                    }
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.name)
                            .font(.title2.bold())
                        if let area = meal.area, let category = meal.category {
                            Text("\(area) · \(category)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Text("₹\(meal.priceInr)")
                            .font(.headline)
                    }

                    cartControl(for: meal, viewModel: viewModel)

                    if !meal.ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ingredients")
                                .font(.headline)
                            ForEach(meal.ingredients, id: \.name) { ingredient in
                                Text(ingredient.measure.isEmpty ? ingredient.name : "\(ingredient.name) — \(ingredient.measure)")
                                    .font(.subheadline)
                            }
                        }
                    }

                    if let instructions = meal.instructions, !instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Instructions")
                                .font(.headline)
                            Text(instructions)
                                .font(.subheadline)
                                .lineLimit(instructionsExpanded ? nil : 4)
                            Button(instructionsExpanded ? "Show less" : "Show more") {
                                withAnimation { instructionsExpanded.toggle() }
                            }
                            .font(.subheadline.bold())
                        }
                    }

                    Text("Prices are synthetic.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
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

    @ViewBuilder
    private func cartControl(for meal: MealDetail, viewModel: DetailViewModel) -> some View {
        if viewModel.qtyInCart == 0 {
            Button {
                Task {
                    await viewModel.addToCart()
                    await environment.refreshCartCount()
                }
            } label: {
                Label("Add to cart", systemImage: "cart.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        } else {
            HStack {
                Text("In cart: \(viewModel.qtyInCart)")
                    .font(.subheadline)
                Spacer()
                Stepper(
                    "Quantity",
                    value: Binding(
                        get: { viewModel.qtyInCart },
                        set: { newValue in
                            Task {
                                await viewModel.setQty(newValue)
                                await environment.refreshCartCount()
                            }
                        }
                    ),
                    in: 0...20
                )
                .labelsHidden()
                .fixedSize()
            }
        }
    }
}
