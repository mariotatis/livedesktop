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
                        // Delete message popup
                        VStack {
                            if downloadsService.showDeleteMessage {
                                Text(downloadsService.deleteMessage)
                                    .padding()
                                    .background(Color.black.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .transition(.opacity)
                            }
                            Spacer()
                        }
                        .animation(.easeInOut(duration: 0.3), value: downloadsService.showDeleteMessage)
                    )
                }
            }
            .background(Color(hex: "#1f1f1f"))
        }
        .background(Color(hex: "#1f1f1f"))
        .frame(minWidth: 1000, minHeight: 700)
        .onAppear {
            print("🎬 DashboardView: onAppear called")
            
            // Auto-select first available display when view appears
            if selectedDisplay == nil && !displayManager.availableDisplays.isEmpty {
                selectedDisplay = displayManager.availableDisplays.first?.name
                print("📺 DashboardView: Auto-selected display: \(selectedDisplay ?? "none")")
            }
            
            // Videos are now loaded at app startup, no need to load here
            print("🎥 DashboardView: Videos loaded at startup - count: \(popularsService.videos.count)")
            print("🔄 DashboardView: Filtered videos count: \(filteredVideos.count)")
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
    }
}


#Preview {
    DashboardView()
        .frame(width: 1200, height: 800)
}
