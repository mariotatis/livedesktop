import SwiftUI

struct VideoGrid: View {
    let filteredVideos: [VideoItem]
    @Binding var likedVideos: Set<String>
    let isLoading: Bool
    let onLoadMore: () -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
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
                        // Trigger load more when reaching the last few items
                        if video.id == filteredVideos.last?.id {
                            onLoadMore()
                        }
                    }
                }
                
                // Loading indicator at bottom
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                    .gridCellColumns(3)
                }
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .background(Color(hex: "#1f1f1f"))
        .zIndex(1)
    }
}

struct VideoCard: View {
    let video: VideoItem
    let isLiked: Bool
    let onLike: (String) -> Void
    
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
                            onLike(video.id)
                        } label: {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .white)
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
            .padding(.leading, 0)
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
