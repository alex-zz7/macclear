import Foundation

enum AppSort: String, CaseIterable, Identifiable {
    case name
    case size

    var id: String { rawValue }

    var title: String {
        switch self {
        case .name: "名称"
        case .size: "大小"
        }
    }
}
