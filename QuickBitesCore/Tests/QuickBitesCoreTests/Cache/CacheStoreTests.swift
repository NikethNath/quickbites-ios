import Testing
import Foundation
@testable import QuickBitesCore

@Suite struct CacheStoreTests {
    private func makeStore() -> CacheStore {
        CacheStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
    }

    @Test func missingKeyReturnsNil() async {
        let store = makeStore()
        let value: [String]? = await store.load("missing")
        #expect(value == nil)
    }

    @Test func savedValueRoundTrips() async {
        let store = makeStore()
        await store.save(["a", "b"], key: "letters")
        let value: [String]? = await store.load("letters")
        #expect(value == ["a", "b"])
    }

    @Test func corruptFileReturnsNilInsteadOfThrowing() async {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = CacheStore(directory: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? Data("not json".utf8).write(to: directory.appendingPathComponent("letters.json"))

        let value: [String]? = await store.load("letters")

        #expect(value == nil)
    }

    @Test func removeClearsTheValue() async {
        let store = makeStore()
        await store.save(["a"], key: "letters")
        await store.remove("letters")
        let value: [String]? = await store.load("letters")
        #expect(value == nil)
    }
}
