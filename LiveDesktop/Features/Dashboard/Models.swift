import SwiftUI

// MARK: - Data Models
struct VideoItem: Identifiable {
    let id: String
    let title: String
    let author: String
    let category: String
}

// MARK: - Dropdown Models
enum DropDownPickerState {
    case top
    case bottom
}
