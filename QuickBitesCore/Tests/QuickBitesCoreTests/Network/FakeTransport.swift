import Foundation
@testable import QuickBitesCore

struct FakeTransport: HTTPTransport {
    let handler: @Sendable (URL) throws -> Data

    func get(_ url: URL) async throws -> Data {
        try handler(url)
    }

    static func json(_ string: String) -> FakeTransport {
        FakeTransport { _ in Data(string.utf8) }
    }
}
