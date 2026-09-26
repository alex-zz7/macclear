import Foundation

struct LibraryAlert: Equatable, Identifiable {
    let id = UUID()
    var title: String
    var message: String
}
