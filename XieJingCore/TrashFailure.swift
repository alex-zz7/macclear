import Foundation

public struct TrashFailure: Sendable, Hashable {
    public var url: URL
    public var message: String

    public init(url: URL, message: String) {
        self.url = url
        self.message = message
    }
}
