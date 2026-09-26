import Foundation

public enum StoreCategoryGroup: String, CaseIterable, Sendable, Identifiable {
    case finance
    case social
    case developer
    case utilities
    case entertainment
    case reading
    case creative
    case other

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .finance: "效率与财务"
        case .social: "社交"
        case .developer: "开发工具"
        case .utilities: "工具"
        case .entertainment: "娱乐"
        case .reading: "信息与阅读"
        case .creative: "创意"
        case .other: "其他"
        }
    }

    public static func group(for storeCategory: String?) -> StoreCategoryGroup {
        switch storeCategory {
        case "public.app-category.business", "public.app-category.finance", "public.app-category.productivity":
            .finance
        case "public.app-category.social-networking":
            .social
        case "public.app-category.developer-tools":
            .developer
        case "public.app-category.utilities":
            .utilities
        case "public.app-category.entertainment",
             "public.app-category.music",
             "public.app-category.video",
             "public.app-category.sports":
            .entertainment
        case "public.app-category.news",
             "public.app-category.reference",
             "public.app-category.education",
             "public.app-category.books":
            .reading
        case "public.app-category.graphics-design", "public.app-category.photography":
            .creative
        default:
            if storeCategory?.contains("game") == true {
                .entertainment
            } else {
                .other
            }
        }
    }
}
