import SwiftUI

struct DashboardView: View {
    // MARK: - State Variables
    @State private var selectedNavItem = "Popular"
    @State private var selectedDisplay: String? = "Built-in Retina Display"
    @State private var searchText = ""
    @State private var selectedFilterOption: String? = "All"
    @State private var likedVideos: Set<String> = []
    
    // MARK: - Data
    private let navItems = ["Popular", "Favorites", "Downloads"]
    private let displays = ["Built-in Retina Display", "External Monitor 1", "External Monitor 2"]
    private let filterOptions = ["All", "Nature", "Cities", "Ocean", "Abstract"]
    
    private let videoData = [
        VideoItem(id: "1", title: "Aurora", author: "Jane Smith", category: "Nature"),
        VideoItem(id: "2", title: "Cyberpunk", author: "Alex Chen", category: "Cities"),
        VideoItem(id: "3", title: "Swirls", author: "John Doe", category: "Abstract"),
        VideoItem(id: "4", title: "Sunset", author: "Jane Smith", category: "Nature"),
        VideoItem(id: "5", title: "Highway", author: "Alex Chen", category: "Cities"),
        VideoItem(id: "6", title: "Fluid", author: "John Doe", category: "Abstract"),
        VideoItem(id: "7", title: "Rainy", author: "Jane Smith", category: "Nature"),
        VideoItem(id: "8", title: "Galaxy", author: "Alex Chen", category: "Abstract")
    ]
    
    // MARK: - Computed Properties
    private var filteredVideos: [VideoItem] {
        let currentFilter = selectedFilterOption ?? "All"
        let filtered = currentFilter == "All" ? videoData : videoData.filter { $0.category == currentFilter }
        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Panel
            LeftPanel(
                selectedNavItem: $selectedNavItem,
                selectedDisplay: $selectedDisplay,
                navItems: navItems,
                displays: displays
            )
            
            // Main Content Area
            VStack(spacing: 0) {
                // Search and Filter Panel
                SearchAndFilterPanel(
                    searchText: $searchText,
                    selectedFilterOption: $selectedFilterOption,
                    filterOptions: filterOptions
                )
                
                // Video Grid
                VideoGrid(
                    filteredVideos: filteredVideos,
                    likedVideos: $likedVideos
                )
            }
            .background(Color(hex: "#1f1f1f"))
        }
        .background(Color(hex: "#1f1f1f"))
        .frame(minWidth: 1000, minHeight: 700)
    }
}


#Preview {
    DashboardView()
        .frame(width: 1200, height: 800)
}
