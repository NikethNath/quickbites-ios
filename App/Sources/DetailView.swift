import SwiftUI

struct DetailView: View {
    let mealId: String

    var body: some View {
        Text("Detail for meal \(mealId) coming soon")
            .navigationTitle("Dish")
    }
}
