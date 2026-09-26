import Foundation
import XieJingCore

struct AppListSection: Identifiable {
    var title: String
    var apps: [InstalledApp]

    var id: String { title }
}
