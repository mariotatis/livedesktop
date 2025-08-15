import SwiftUI

struct DashboardView: View {
    // MARK: - State Variables
    @State private var selectedNavItem = "Popular"
    @State private var selectedDisplay: String? = nil
    @State private var searchText = ""
    @State private var selectedFilterOption: String? = "All"
    @State private var mirrorDisplays = false
    @State private var selectedVideo: VideoItem? = nil
    
    // MARK: - Managers
    @ObservedObject private var displayManager = DisplayManager.shared
    @ObservedObject private var popularsService = PopularsService.shared
    @ObservedObject private var favoritesService = FavoritesService.shared
    @ObservedObject private var downloadsService = DownloadsService.shared
    @ObservedObject private var wallpaperService = WallpaperService.shared
    
    // MARK: - Data
    private let navItems = ["Popular", "Favorites", "Downloads"]
    private let filterOptions = ["All", "Nature", "Cities", "Ocean", "Abstract"]
    
    // MARK: - Computed Properties
    private var filteredVideos: [VideoItem] {
        let videos: [VideoItem]
        
        // Switch between Popular, Favorites, and Downloads based on selected nav item
        switch selectedNavItem {
        case "Favorites":
            let favoriteVideos = favoritesService.getFavoriteVideos(from: popularsService.videos)
            videos = favoriteVideos.map { $0.videoItem }
        case "Downloads":
            let downloadedVideos = downloadsService.getDownloadedVideos(from: popularsService.videos)
            videos = downloadedVideos.map { $0.videoItem }
        default: // Popular
            videos = popularsService.videos.map { $0.videoItem }
        }
        
        let currentFilter = selectedFilterOption ?? "All"
        let filtered = currentFilter == "All" ? videos : videos.filter { $0.category == currentFilter }
        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.author.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Panel
            LeftPanel(
                selectedNavItem: $selectedNavItem,
                selectedDisplay: $selectedDisplay,
                mirrorDisplays: $mirrorDisplays,
                selectedVideo: $selectedVideo,
                navItems: navItems,
                displays: displayManager.getDisplayNames()
            )
            .frame(width: 280)
            
            // Main Content Area
            VStack(spacing: 0) {
                // Search and Filter Panel
                SearchAndFilterPanel(
                    searchText: $searchText,
                    selectedFilterOption: $selectedFilterOption,
                    filterOptions: filterOptions
                )
                
                // Video Grid
                if popularsService.videos.isEmpty && popularsService.isLoading {
                    // Main loading state
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Loading videos...")
                            .foregroundColor(.gray)
                            .padding(.top, 16)
                        Spacer()
                    }
                } else {
                    VideoGrid(
                        filteredVideos: filteredVideos,
                        likedVideos: .constant(favoritesService.favoriteVideoIds),
                        isLoading: popularsService.isLoading,
                        selectedVideo: $selectedVideo,
                        onLoadMore: {
                            if selectedNavItem == "Popular" {
                                popularsService.loadNextPage()
                            }
                        }
                    )
                    .overlay(
                        // Status message popups
                        VStack {
                            if downloadsService.showDeleteMessage {
                                Text(downloadsService.deleteMessage)
                                    .padding()
                                    .background(Color.black.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .transition(.opacity)
                            }
                            
                            if wallpaperService.showWallpaperMessage {
                                Text(wallpaperService.wallpaperMessage)
                                    .padding()
                                    .background(Color.black.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .transition(.opacity)
                            }
                            Spacer()
                        }
                        .animation(.easeInOut(duration: 0.3), value: downloadsService.showDeleteMessage || wallpaperService.showWallpaperMessage)
                    )
                }
            }
            .background(Color(hex: "#1f1f1f"))
        }
        .background(Color(hex: "#1f1f1f"))
        .frame(minWidth: 1000, minHeight: 700)
        .onAppear {
            // Load saved settings
            mirrorDisplays = wallpaperService.getMirrorDisplays()
            if let savedDisplay = wallpaperService.getSelectedDisplay() {
                selectedDisplay = savedDisplay
                // Load the video for this display
                loadVideoForCurrentDisplay()
            } else if selectedDisplay == nil && !displayManager.availableDisplays.isEmpty {
                selectedDisplay = displayManager.availableDisplays.first?.name
                loadVideoForCurrentDisplay()
            }
        }
        .onChange(of: selectedDisplay) { newDisplay in
            // When display changes, save the selection but don't override user's current video choice
            if let displayName = newDisplay {
                wallpaperService.saveSelectedDisplay(displayName)
                // Only load saved video if no video is currently selected by user
                if selectedVideo == nil {
                    loadVideoForDisplay(displayName)
                }
            }
        }
        .onChange(of: displayManager.availableDisplays) { displays in
            // Handle display changes - ensure selected display is still valid
            if let currentSelection = selectedDisplay,
               !displays.contains(where: { $0.name == currentSelection }) {
                // Current selection is no longer available, select first available
                selectedDisplay = displays.first?.name
            } else if selectedDisplay == nil && !displays.isEmpty {
                // No selection but displays are available, select first
                selectedDisplay = displays.first?.name
            }
        }
        .onChange(of: selectedVideo) { newVideo in
            print("🔍 DashboardView: selectedVideo changed to: \(newVideo?.id ?? "nil")")
        }
    }
    
    // MARK: - Helper Methods
    private func loadVideoForCurrentDisplay() {
        if let displayName = selectedDisplay {
            loadVideoForDisplay(displayName)
        }
    }
    
    private func loadVideoForDisplay(_ displayName: String) {
        if let videoId = wallpaperService.getVideoForDisplay(displayName) {
            // Find the video in our current videos list
            if let video = findVideoById(videoId) {
                selectedVideo = video
            } else {
                // Video not found in current list, but check if it's downloaded
                // Create a VideoItem from the saved video ID if it exists locally
                if downloadsService.isDownloaded(videoId: videoId) {
                    selectedVideo = createVideoItemFromDownloadedVideo(videoId: videoId)
                }
            }
        } else {
            // No video set for this display, check for any downloaded video as fallback
            if let firstDownloadedVideoId = Array(downloadsService.downloadedVideoIds).first,
               let fallbackVideo = createVideoItemFromDownloadedVideo(videoId: firstDownloadedVideoId) {
                selectedVideo = fallbackVideo
            } else {
                selectedVideo = nil
            }
        }
    }
    
    private func findVideoById(_ videoId: String) -> VideoItem? {
        return popularsService.videos.first { String($0.id) == videoId }?.videoItem
    }
    
    private func createVideoItemFromDownloadedVideo(videoId: String) -> VideoItem? {
        guard downloadsService.isDownloaded(videoId: videoId),
              let localURL = downloadsService.getLocalVideoURL(videoId: videoId) else {
            return nil
        }
        
        // Create a VideoItem for the downloaded video
        return VideoItem(
            id: videoId,
            title: "Downloaded Video",
            author: "Local",
            category: "Downloaded",
            imageURL: nil, // No thumbnail for local videos
            videoURL: localURL.absoluteString
        )
    }
}


#Preview {
    DashboardView()
        .frame(width: 1200, height: 800)
}
