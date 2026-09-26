import Foundation

public enum ItemCategory: String, CaseIterable, Sendable, Hashable, Identifiable {
    case application
    case preferences
    case applicationSupport
    case containers
    case groupContainers
    case caches
    case savedState
    case logs
    case launchAgents
    case receipts
    case plugIns
    case other

    public var id: String { rawValue }

    public var sortIndex: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
