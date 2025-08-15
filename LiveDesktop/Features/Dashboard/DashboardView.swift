import SwiftUI

struct DashboardView: View {
    // MARK: - State Variables
    @State private var selectedNavItem = "Popular"
    @State private var selectedDisplay: String? = nil
    @State private var searchText = ""
    @State private var selectedFilterOption: String? = "All"
    @State private var likedVideos: Set<String> = []
    
    // MARK: - Managers
    @ObservedObject private var displayManager = DisplayManager.shared
    @StateObject private var popularsService = PopularsService()
    
    // MARK: - Data
    private let navItems = ["Popular", "Favorites", "Downloads"]
    private let filterOptions = ["All", "Nature", "Cities", "Ocean", "Abstract"]
    
    // MARK: - Computed Properties
    private var filteredVideos: [VideoItem] {
        let videos = popularsService.videos.map { $0.videoItem }
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
                        likedVideos: $likedVideos,
                        isLoading: popularsService.isLoading,
                        onLoadMore: {
                            popularsService.loadNextPage()
                        }
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
            
            // Load popular videos when view appears
            print("🎥 DashboardView: Checking if videos are empty - count: \(popularsService.videos.count)")
            if popularsService.videos.isEmpty {
                print("🚀 DashboardView: Calling popularsService.loadPopularVideos()")
                popularsService.loadPopularVideos()
            } else {
                print("⚠️ DashboardView: Videos already loaded, skipping API call")
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
    }
}


#Preview {
    DashboardView()
        .frame(width: 1200, height: 800)
}
