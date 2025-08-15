import SwiftUI

// MARK: - Data Models
struct VideoItem: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let author: String
    let category: String
    let imageURL: String?
    let videoURL: String?
    let videoURLHD: String? // Add HD URL for downloads
    
    init(id: String, title: String, author: String, category: String, imageURL: String? = nil, videoURL: String? = nil, videoURLHD: String? = nil) {
        self.id = id
        self.title = title
        self.author = author
        self.category = category
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.videoURLHD = videoURLHD
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
