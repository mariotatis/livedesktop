import SwiftUI

struct VideoGrid: View {
    let filteredVideos: [VideoItem]
    @Binding var likedVideos: Set<String>
    let isLoading: Bool
    let onLoadMore: () -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 32), count: 3), spacing: 32) {
                ForEach(filteredVideos) { video in
                    VideoCard(
                        video: video,
                        isLiked: likedVideos.contains(video.id)
                    ) { videoId in
                        if likedVideos.contains(videoId) {
                            likedVideos.remove(videoId)
                        } else {
                            likedVideos.insert(videoId)
                        }
                    }
                    .onAppear {
                        // Trigger load more when reaching one of the last 3 items
                        if let lastIndex = filteredVideos.lastIndex(where: { $0.id == video.id }),
                           lastIndex >= filteredVideos.count - 3 {
                            print("🔄 VideoGrid: Near end (item \(lastIndex + 1)/\(filteredVideos.count)), triggering load more")
                            onLoadMore()
                        }
                    }
                }
                
                // Loading indicator at bottom
                if isLoading && !filteredVideos.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        Text("Loading more...")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                    .gridCellColumns(3)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(hex: "#1f1f1f"))
        .zIndex(1)
    }
}

struct VideoCard: View {
    let video: VideoItem
    let isLiked: Bool
    let onLike: (String) -> Void
    
    @ObservedObject private var favoritesService = FavoritesService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Video Preview
            ZStack {
                HoverVideoPlayer(imageURL: video.imageURL, videoURL: video.videoURL)
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(12)
                
                // Action Buttons
                VStack {
                    HStack {
                        Spacer()
                        
                        // Download Button
                        Button {
                            // Download action
                        } label: {
                            Image(systemName: "arrow.down")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        
                        // Like Button
                        Button {
                            favoritesService.toggleFavorite(videoId: video.id)
                        } label: {
                            Image(systemName: favoritesService.isFavorite(videoId: video.id) ? "heart.fill" : "heart")
                                .foregroundColor(favoritesService.isFavorite(videoId: video.id) ? .red : .white)
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    }
                    Spacer()
                }
                .padding(12)
            }
            
            // Author
            HStack {
                Text("by \(video.author)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(.leading, 8)
            .padding(.trailing, 4)
            .padding(.top, 8)
        }
        .background(Color.clear)
        .cornerRadius(12)
    }
    
    private func colorForVideo(_ title: String) -> Color {
        switch title {
        case "Aurora":
            return Color.purple
        case "Cyberpunk":
            return Color.pink
        case "Swirls":
            return Color.gray
        case "Sunset":
            return Color.orange
        case "Highway":
            return Color.blue
        case "Fluid":
            return Color.cyan
        case "Rainy":
            return Color.indigo
        case "Galaxy":
            return Color.purple
        default:
            return Color.gray
        }
    }
}
