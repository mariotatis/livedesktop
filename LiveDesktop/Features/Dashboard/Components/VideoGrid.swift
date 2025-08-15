import SwiftUI

struct VideoGrid: View {
    let filteredVideos: [VideoItem]
    @Binding var likedVideos: Set<String>
    let isLoading: Bool
    @Binding var selectedVideo: VideoItem?
    let onLoadMore: () -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 32), count: 3), spacing: 32) {
                ForEach(filteredVideos) { video in
                    LazyVideoCard(
                        video: video,
                        isLiked: likedVideos.contains(video.id),
                        selectedVideo: $selectedVideo
                    ) { videoId in
                        if likedVideos.contains(videoId) {
                            likedVideos.remove(videoId)
                        } else {
                            likedVideos.insert(videoId)
                        }
                    }
                    .onAppear {
                        // Trigger load more when reaching one of the last 6 items with debouncing
                        if let lastIndex = filteredVideos.lastIndex(where: { $0.id == video.id }),
                           lastIndex >= filteredVideos.count - 6 {
                            // Debounce the load more call to prevent multiple rapid calls
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onLoadMore()
                            }
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

struct LazyVideoCard: View {
    let video: VideoItem
    let isLiked: Bool
    @Binding var selectedVideo: VideoItem?
    let onLike: (String) -> Void
    
    @ObservedObject private var favoritesService = FavoritesService.shared
    @ObservedObject private var downloadsService = DownloadsService.shared
    @State private var hasLoaded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Video Preview - Load once and keep loaded
            ZStack {
                // Always maintain the frame size
                Rectangle()
                    .fill(Color.clear)
                    .aspectRatio(16/9, contentMode: .fit)
                
                if hasLoaded {
                    HoverVideoPlayer(imageURL: video.imageURL, videoURL: video.videoURL, videoId: video.id)
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(12)
                        .onTapGesture {
                            selectedVideo = video
                        }
                } else {
                    // Placeholder while not loaded
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(12)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        )
                }
            }
            .overlay(
                ZStack {
                    // Download Progress Bar
                    if downloadsService.isDownloading(videoId: video.id) {
                        VStack {
                            Spacer()
                            ProgressView(value: downloadsService.getDownloadProgress(videoId: video.id))
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(4)
                                .padding(.horizontal, 12)
                                .padding(.bottom, 8)
                        }
                    }
                    
                    // Action Buttons
                    VStack {
                        HStack {
                            Spacer()
                            
                            // Download/Delete Button
                            Button {
                                if downloadsService.isDownloaded(videoId: video.id) {
                                    downloadsService.deleteVideo(videoId: video.id)
                                } else {
                                    // Get HD URL from PopularsService
                                    if let popularVideo = PopularsService.shared.videos.first(where: { String($0.id) == video.id }) {
                                        downloadsService.downloadVideo(videoId: video.id, hdURL: popularVideo.videoFileHd)
                                    }
                                }
                            } label: {
                                Image(systemName: downloadsService.isDownloaded(videoId: video.id) ? "trash" : "arrow.down")
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
            )
            
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
        .onAppear {
            // Load once and keep loaded for caching
            if !hasLoaded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    hasLoaded = true
                }
            }
        }
    }
    
}

// MARK: - Helper Functions
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
