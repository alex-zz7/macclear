import Foundation

public struct TrashReport: Sendable, Hashable {
    public var moved: [URL]
    public var failures: [TrashFailure]

    public init(moved: [URL], failures: [TrashFailure]) {
        self.moved = moved
        self.failures = failures
    }
}
