import Cocoa
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarManager = StatusBarManager()
    private let wallpaperManager = WallpaperManager()
    private var dashboardWindow: NSWindow?
    
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
    
    func statusBarDidOpenDashboard() {
        openDashboard()
    }
    
    func statusBarDidRequestQuit() {
        NSApp.terminate(nil)
    }
    
    private func openDashboard() {
        if dashboardWindow == nil {
            let dashboardView = DashboardView()
            let hostingController = NSHostingController(rootView: dashboardView)
            
            dashboardWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            dashboardWindow?.title = "Live Desktop Dashboard"
            dashboardWindow?.contentViewController = hostingController
            dashboardWindow?.center()
            dashboardWindow?.setFrameAutosaveName("DashboardWindow")
            
            // Set minimum size
            dashboardWindow?.minSize = NSSize(width: 1000, height: 700)
            
            // Handle window closing
            dashboardWindow?.delegate = self
            dashboardWindow?.isReleasedWhenClosed = false
        }
        
        dashboardWindow?.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - NSWindowDelegate
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == dashboardWindow {
            dashboardWindow?.delegate = nil
            dashboardWindow = nil
            
            // Only change activation policy if no other windows are open
            DispatchQueue.main.async {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Always allow window to close
        return true
    }
}
