import SwiftUI
import AVKit

struct LeftPanel: View {
    @Binding var selectedNavItem: String
    @Binding var selectedDisplay: String?
    @Binding var mirrorDisplays: Bool
    
    let navItems: [String]
    let displays: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Menu
            VStack(spacing: 8) {
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
                
                // Mirror Displays Toggle
                HStack {
                    Text("Mirror Displays")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $mirrorDisplays)
                        .toggleStyle(SwitchToggleStyle())
                        .scaleEffect(0.8)
                }
                .padding(.horizontal, 20)
                
                // Display Dropdown (hidden when mirroring)
                if !mirrorDisplays {
                    DropDownPicker(
                        selection: $selectedDisplay,
                        options: displays,
                        maxWidth: 240,
                        placeholder: "Select Display"
                    )
                    .padding(.horizontal, 20)
                }
                
                // Preview Window
                LoopingVideoPlayer(videoFileName: "video")
                    .frame(height: 120)
                    .cornerRadius(8)
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
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .frame(width: 280)
        .background(Color(hex: "#181818"))
    }
    
    private func iconForNavItem(_ item: String) -> String {
        switch item {
        case "Popular":
            return "flame"
        case "Favorites":
            return "heart"
        case "Downloads":
            return "arrow.down.circle"
        default:
            return "circle"
        }
    }
}

struct NavigationButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 24)
                .foregroundColor(isSelected ? .purple : .gray)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.purple.opacity(0.2) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}
