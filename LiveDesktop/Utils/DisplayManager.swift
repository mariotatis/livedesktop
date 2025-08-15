import Cocoa
import SwiftUI
import Combine

class DisplayManager: ObservableObject {
    static let shared = DisplayManager()
    
    @Published var availableDisplays: [DisplayInfo] = []
    
    struct DisplayInfo: Identifiable, Hashable {
        let id: String
        let name: String
        let frame: NSRect
        let isMain: Bool
        let screen: NSScreen
        
        init(screen: NSScreen) {
            self.screen = screen
            self.id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? String ?? UUID().uuidString
            self.frame = screen.frame
            self.isMain = screen == NSScreen.main
            
            // Generate a user-friendly display name
            if self.isMain {
                self.name = "Built-in Retina Display"
            } else {
                // Try to get a more descriptive name, fallback to generic naming
                let displayIndex = NSScreen.screens.firstIndex(of: screen) ?? 0
                self.name = "External Monitor \(displayIndex)"
            }
        }
    }
    
    private init() {
        updateDisplayList()
        setupDisplayChangeMonitoring()
    }
    
    private func setupDisplayChangeMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDisplayConfigurationChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func handleDisplayConfigurationChange() {
        // Delay the update slightly to ensure display changes are fully processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.updateDisplayList()
        }
    }
    
    private func updateDisplayList() {
        let newDisplays = NSScreen.screens.map { DisplayInfo(screen: $0) }
        
        // Only update if the display list actually changed
        if newDisplays != availableDisplays {
            availableDisplays = newDisplays
            print("Display configuration updated: \(availableDisplays.count) displays detected")
            for display in availableDisplays {
                print("- \(display.name) (Main: \(display.isMain))")
            }
        }
    }
    
    // MARK: - Public Interface for Dashboard
    func getDisplayNames() -> [String] {
        return availableDisplays.map { $0.name }
    }
    
    func getDisplayInfo(for name: String) -> DisplayInfo? {
        return availableDisplays.first { $0.name == name }
    }
    
    // MARK: - Public Interface for WallpaperManager
    func getAllScreens() -> [NSScreen] {
        return availableDisplays.map { $0.screen }
    }
    
    func getScreen(for displayName: String) -> NSScreen? {
        return availableDisplays.first { $0.name == displayName }?.screen
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
}
