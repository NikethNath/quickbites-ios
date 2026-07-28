import SwiftUI
import QuickBitesCore

struct CartView: View {
    @Environment(AppEnvironment.self) private var environment
    @Binding var selectedTab: Tab
    @State private var viewModel: CartViewModel?
    @State private var isCheckingOut = false

    var body: some View {
        Group {
            if let viewModel {
                content(for: viewModel.state, viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Cart")
        .task {
            if viewModel == nil {
                viewModel = CartViewModel(repository: environment.orderRepository)
            }
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func content(for state: CartViewModel.State, viewModel: CartViewModel) -> some View {
        switch state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            ContentUnavailableView("Your cart is empty", systemImage: "cart")

        case .content(let items):
            VStack(spacing: 0) {
                List {
                    ForEach(items) { item in
                        CartRow(item: item) { newQty in
                            Task {
                                await viewModel.setQty(
                                    mealId: item.mealId,
                                    qty: newQty,
                                    name: item.name,
                                    priceInr: item.priceInr,
                                    thumbURL: item.thumbURL
                                )
                                await environment.refreshCartCount()
                            }
                        }
                    }
                }
                .listStyle(.plain)

                VStack(spacing: 8) {
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text("₹\(viewModel.total)")
                            .font(.headline)
                    }

                    Button {
                        Task {
                            isCheckingOut = true
                            let success = await viewModel.checkout()
                            await environment.refreshCartCount()
                            isCheckingOut = false
                            if success { selectedTab = .orders }
                        }
                    } label: {
                        if isCheckingOut {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Checkout")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isCheckingOut)

                    Text("Prices are synthetic.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.bar)
            }
        }
    }
}

private struct CartRow: View {
    let item: CartItem
    let onQtyChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.thumbURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.secondary.opacity(0.2)
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                Text("₹\(item.priceInr) × \(item.qty)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Stepper(
                "Quantity",
                value: Binding(get: { item.qty }, set: onQtyChange),
                in: 0...20
            )
            .labelsHidden()
            .fixedSize()
        }
        .accessibilityElement(children: .combine)
    }
}
