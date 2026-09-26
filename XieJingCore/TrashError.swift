import Foundation

public enum TrashError: Error, Sendable, Equatable {
    case blocked(URL)
}
