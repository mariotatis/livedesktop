import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct DropDownMenu: View {
    let options: [String]
    var menuWidth: CGFloat = 180
    var buttonHeight: CGFloat = 48
    var maxItemDisplayed: Int = 3
    
    @Binding var selectedOptionIndex: Int
    @Binding var showDropdown: Bool
    
    @State private var scrollPosition: Int?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // selected item
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDropdown.toggle()
                }
            }, label: {
                HStack(spacing: 12) {
                    Text(options[selectedOptionIndex])
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees((showDropdown ? -180 : 0)))
                }
                .foregroundColor(.white)
            })
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(width: menuWidth, height: buttonHeight)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
            )
            .cornerRadius(25)
            .contentShape(Rectangle())
            
            // selection menu (dropdown) - positioned absolutely
            if showDropdown {
                let scrollViewHeight: CGFloat = min(CGFloat(options.count) * buttonHeight, CGFloat(maxItemDisplayed) * buttonHeight)
                
                VStack(spacing: 0) {
                    ForEach(0..<options.count, id: \.self) { index in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedOptionIndex = index
                                showDropdown = false
                            }
                        }, label: {
                            HStack {
                                Text(options[index])
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                                Spacer()
                                if (index == selectedOptionIndex) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(hex: "#181818"))
                            .contentShape(Rectangle())
                        })
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: menuWidth, height: buttonHeight)
                    }
                }
                .background(Color(hex: "#181818"))
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .frame(width: menuWidth, height: scrollViewHeight)
                .offset(y: buttonHeight + 5)
                .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
                .zIndex(10000)
            }
        }
        .frame(width: menuWidth, height: buttonHeight)
        .zIndex(9999)
    }
}

struct DashboardView: View {
    @State private var selectedNavItem = "Popular"
    @State private var selectedDisplay: String? = "Built-in Retina Display"
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var selectedFilterIndex = 0
    @State private var selectedFilterOption: String? = "All"
    @State private var showFilterDropdown = false
    @State private var likedVideos: Set<String> = []
    
    let navItems = ["Popular", "Favorites", "Downloaded"]
    let displays = ["Built-in Retina Display", "External Monitor 1", "External Monitor 2"]
    let filterOptions = ["All", "Nature", "Cities", "Ocean", "Abstract"]
    
    // Dummy video data
    let videoData = [
        VideoItem(id: "1", title: "Aurora", author: "Jane Smith", category: "Nature"),
        VideoItem(id: "2", title: "Cyberpunk", author: "Alex Chen", category: "Cities"),
        VideoItem(id: "3", title: "Swirls", author: "John Doe", category: "Abstract"),
        VideoItem(id: "4", title: "Sunset", author: "Jane Smith", category: "Nature"),
        VideoItem(id: "5", title: "Highway", author: "Alex Chen", category: "Cities"),
        VideoItem(id: "6", title: "Fluid", author: "John Doe", category: "Abstract"),
        VideoItem(id: "7", title: "Rainy", author: "Jane Smith", category: "Nature"),
        VideoItem(id: "8", title: "Galaxy", author: "Alex Chen", category: "Abstract")
    ]
    
    var filteredVideos: [VideoItem] {
        let currentFilter = selectedFilterOption ?? "All"
        let filtered = currentFilter == "All" ? videoData : videoData.filter { $0.category == currentFilter }
        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            VStack(alignment: .leading, spacing: 0) {
                // Navigation Menu
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(navItems, id: \.self) { item in
                        NavigationButton(
                            title: item,
                            icon: iconForNavItem(item),
                            isSelected: selectedNavItem == item
                        ) {
                            selectedNavItem = item
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                
                Spacer()
                
                // Display Management Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "display")
                            .foregroundColor(.white)
                            .frame(width: 20)
                        Text("Active Display")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    
                    // Display Dropdown
                    DropDownPicker(
                        selection: $selectedDisplay,
                        options: displays,
                        maxWidth: 240,
                        placeholder: "Select Display"
                    )
                    .padding(.horizontal, 20)
                    
                    // Preview Window
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.4)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 120)
                        .overlay(
                            Text("Aurora Preview")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        )
                        .padding(.horizontal, 20)
                    
                    // Set Live Desktop Button
                    Button(action: {
                        // Action to set wallpaper
                    }) {
                        Text("Set Live Desktop")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.pink]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle()) // remove macOS default styling
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .frame(width: 280)
            .background(Color(hex: "#181818"))
            
            // Main Content Area
            VStack(spacing: 0) {
                // Top Bar with Search and Filter
                HStack(spacing: 16) {
                    // Search Field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search wallpapers...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 48)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
                    )
                    .cornerRadius(25)
                    
                    // Filter Dropdown
                    DropDownPicker(
                        selection: $selectedFilterOption,
                        options: filterOptions,
                        maxWidth: 180,
                        placeholder: "Filter"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .zIndex(1000)
                
                // Video Grid
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
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .background(Color(hex: "#1f1f1f"))
                .zIndex(1)
            }
            .background(Color(hex: "#1f1f1f"))
        }
        .background(Color(hex: "#1f1f1f"))
        .preferredColorScheme(.dark)
        .frame(minWidth: 1000, minHeight: 700)
    }
    
    private func iconForNavItem(_ item: String) -> String {
        switch item {
        case "Popular": return "flame.fill"
        case "Favorites": return "heart.fill"
        case "Downloaded": return "arrow.down.circle.fill"
        default: return "circle.fill"
        }
    }
}

struct NavigationButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .purple : .gray)
                    .font(.system(size: 18))
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(isSelected ? .white : .gray)
                    .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.purple.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorForVideo(video.title))
                    .aspectRatio(16/9, contentMode: .fit)
                
                // Like Button
                VStack {
                    HStack {
                        Spacer()
                        
                        Button {
                            onLike(video.id)
                        } label: {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .white)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                    }
                    Spacer()
                }
                .padding(12)
            }
            
            // Author and Actions
            HStack {
                Text("by \(video.author)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        // Preview action
                    } label: {
                        Image(systemName: "eye")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 24, height: 24)
                    
                    Button {
                        // Download action
                    } label: {
                        Image(systemName: "arrow.down.circle")
                            .foregroundColor(.purple)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 4)
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

struct VideoItem: Identifiable {
    let id: String
    let title: String
    let author: String
    let category: String
}

enum DropDownPickerState {
    case top
    case bottom
}

struct DropDownPicker: View {
    @Binding var selection: String?
    var state: DropDownPickerState = .bottom
    var options: [String]
    var maxWidth: CGFloat = 180
    var placeholder: String = "Select"
    
    @State var showDropdown = false
    @SceneStorage("drop_down_zindex") private var index = 1000.0
    @State var zindex = 1000.0
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            VStack(spacing: 0) {
                if state == .top && showDropdown {
                    OptionsView()
                }
                
                HStack {
                    Text(selection == nil ? placeholder : selection!)
                        .foregroundColor(selection != nil ? .white : .gray)
                    
                    Spacer(minLength: 0)
                    
                    Image(systemName: state == .top ? "chevron.up" : "chevron.down")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees((showDropdown ? -180 : 0)))
                }
                .padding(.horizontal, 20)
                .frame(width: maxWidth, height: 48)
                .background(Color.clear)
                .contentShape(.rect)
                .onTapGesture {
                    index += 1
                    zindex = index
                    withAnimation(.snappy) {
                        showDropdown.toggle()
                    }
                }
                .zIndex(10)
                
                if state == .bottom && showDropdown {
                    OptionsView()
                }
            }
            .clipped()
            .background(Color(hex: "#1f1f1f"))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
            )
            .cornerRadius(25)
            .frame(height: size.height, alignment: state == .top ? .bottom : .top)
        }
        .frame(width: maxWidth, height: 48)
        .zIndex(zindex)
    }
    
    func OptionsView() -> some View {
        VStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                HStack {
                    Text(option)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .opacity(selection == option ? 1 : 0)
                }
                .animation(.none, value: selection)
                .frame(height: 40)
                .contentShape(.rect)
                .padding(.horizontal, 15)
                .onTapGesture {
                    withAnimation(.snappy) {
                        selection = option
                        showDropdown.toggle()
                    }
                }
            }
        }
        .background(Color(hex: "#1f1f1f"))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            // Custom border without top edge
            Path { path in
                let rect = CGRect(x: 0, y: 0, width: maxWidth, height: CGFloat(options.count * 40))
                let cornerRadius: CGFloat = 25
                
                // Start from top-left (no top border)
                path.move(to: CGPoint(x: 0, y: 0))
                
                // Left border
                path.addLine(to: CGPoint(x: 0, y: rect.height - cornerRadius))
                path.addQuadCurve(to: CGPoint(x: cornerRadius, y: rect.height), 
                                control: CGPoint(x: 0, y: rect.height))
                
                // Bottom border
                path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: rect.height))
                path.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height - cornerRadius), 
                                control: CGPoint(x: rect.width, y: rect.height))
                
                // Right border
                path.addLine(to: CGPoint(x: rect.width, y: 0))
            }
            .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
        )
        .transition(.move(edge: state == .top ? .bottom : .top).combined(with: .opacity).animation(.easeInOut(duration: 0.15)))
        .zIndex(1)
    }
}

#Preview {
    DashboardView()
        .frame(width: 1200, height: 800)
}
