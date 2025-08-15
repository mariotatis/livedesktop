import SwiftUI

// MARK: - Data Models
struct VideoItem: Identifiable, Equatable {
    let id: String
    let title: String
    let author: String
    let category: String
    let imageURL: String?
    let videoURL: String?
    
    init(id: String, title: String, author: String, category: String, imageURL: String? = nil, videoURL: String? = nil) {
        self.id = id
        self.title = title
        self.author = author
        self.category = category
        self.imageURL = imageURL
        self.videoURL = videoURL
    }
    
    static func == (lhs: VideoItem, rhs: VideoItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Dropdown Models
enum DropDownPickerState {
    case top
    case bottom
}
