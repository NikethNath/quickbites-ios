import SwiftUI
import QuickBitesCore

struct OrdersView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel: OrdersViewModel?
    @State private var expandedOrderIds: Set<UUID> = []

    var body: some View {
        Group {
            if let viewModel {
                content(for: viewModel.state)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Orders")
        .task {
            if viewModel == nil {
                viewModel = OrdersViewModel(repository: environment.orderRepository)
            }
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func content(for state: OrdersViewModel.State) -> some View {
        switch state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            ContentUnavailableView("No orders yet", systemImage: "list.bullet.rectangle")

        case .content(let orders):
            List(orders) { order in
                DisclosureGroup(isExpanded: Binding(
                    get: { expandedOrderIds.contains(order.id) },
                    set: { isExpanded in
                        if isExpanded {
                            expandedOrderIds.insert(order.id)
                        } else {
                            expandedOrderIds.remove(order.id)
                        }
                    }
                )) {
                    ForEach(order.lines, id: \.mealId) { line in
                        HStack {
                            Text(line.name)
                            Spacer()
                            Text("×\(line.qty)")
                                .foregroundStyle(.secondary)
                            Text("₹\(line.priceInr * line.qty)")
                        }
                        .font(.subheadline)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(order.placedAt, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("₹\(order.total) · \(order.lines.count) item\(order.lines.count == 1 ? "" : "s")")
                            .font(.headline)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}
