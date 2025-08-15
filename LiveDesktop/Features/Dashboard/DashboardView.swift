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
    
    // MARK: - Data
    private let navItems = ["Popular", "Favorites", "Downloads"]
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
                displays: displayManager.getDisplayNames()
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
        .onAppear {
            // Auto-select first available display when view appears
            if selectedDisplay == nil && !displayManager.availableDisplays.isEmpty {
                selectedDisplay = displayManager.availableDisplays.first?.name
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
