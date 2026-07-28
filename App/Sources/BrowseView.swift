import SwiftUI

struct BrowseView: View {
    let title: String

    var body: some View {
        Text("Browse — \(title) coming soon")
            .navigationTitle(title)
    }
}
