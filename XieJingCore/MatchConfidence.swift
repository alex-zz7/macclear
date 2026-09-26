import Foundation

public enum MatchConfidence: Int, Sendable, Hashable, Comparable {
    case likely = 0
    case certain = 1

    public static func < (lhs: MatchConfidence, rhs: MatchConfidence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
