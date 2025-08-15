import Foundation

// MARK: - API Response Models
struct PopularVideosResponse: Codable {
    let data: PopularVideosData
}

struct PopularVideosData: Codable {
    let totalResults: Int
    let page: Int
    let perPage: Int
    let videos: [PopularVideo]
    
    enum CodingKeys: String, CodingKey {
        case totalResults = "total_results"
        case page
        case perPage = "per_page"
        case videos
    }
}

struct PopularVideo: Codable, Identifiable {
    let id = UUID()
    let image: String
    let userName: String
    let videoFileHd: String
    let videoFileSd: String
    let videoPictures: String
    let width: Int
    let height: Int
    
    enum CodingKeys: String, CodingKey {
        case image
        case userName = "user_name"
        case videoFileHd = "video_file_hd"
        case videoFileSd = "video_file_sd"
        case videoPictures = "video_pictures"
        case width
        case height
    }
}

// MARK: - UI Models
extension PopularVideo {
    var videoItem: VideoItem {
        return VideoItem(
            id: id.uuidString,
            title: "Video", // API doesn't provide title, using default
            author: userName,
            category: "Popular", // Default category for popular videos
            imageURL: image,
            videoURL: videoFileSd
        )
    }
}
