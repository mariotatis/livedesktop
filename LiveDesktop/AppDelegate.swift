import Cocoa
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarManager = StatusBarManager()
    private let wallpaperManager = WallpaperManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Setup managers
        setupManagers()
        
        // Start with wallpaper enabled
        wallpaperManager.enableWallpaper()
    }
    
    private func setupManagers() {
        // Configure status bar manager
        statusBarManager.delegate = self
        statusBarManager.setupStatusBar()
    }
}

// MARK: - StatusBarManagerDelegate
extension AppDelegate: StatusBarManagerDelegate {
    var isWallpaperEnabled: Bool {
        return wallpaperManager.isWallpaperEnabled
    }
    
    var isLaunchAtLoginEnabled: Bool {
        return SMAppService.mainApp.status == .enabled
    }
    
    func statusBarDidToggleWallpaper() {
        wallpaperManager.toggleWallpaper()
    }
    
    func statusBarDidToggleLaunchAtLogin() {
        do {
            if isLaunchAtLoginEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }
    }
    
    func statusBarDidRequestQuit() {
        NSApp.terminate(nil)
    }
}
