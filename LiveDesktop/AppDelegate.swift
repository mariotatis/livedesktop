import Cocoa
import SwiftUI
import Kingfisher
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Managers
    private var statusBarManager: StatusBarManager?
    private var wallpaperManager: WallpaperManager?
    private var dashboardWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Configure Kingfisher cache
        configureImageCache()
        
        // Setup managers
        setupManagers()
        
        // Start with wallpaper enabled
        wallpaperManager?.enableWallpaper()
    }
    
    private func setupManagers() {
        
        // Initialize managers
        statusBarManager = StatusBarManager()
        wallpaperManager = WallpaperManager()
        
        // Configure status bar manager
        statusBarManager?.delegate = self
        statusBarManager?.setupStatusBar()
        
        // Start loading popular videos in background
        PopularsService.shared.loadPopularVideos()
    }
}

// MARK: - StatusBarManagerDelegate
extension AppDelegate: StatusBarManagerDelegate {
    var isWallpaperEnabled: Bool {
        return wallpaperManager?.isWallpaperEnabled ?? false
    }
    
    var isLaunchAtLoginEnabled: Bool {
        return SMAppService.mainApp.status == .enabled
    }
    
    func statusBarDidToggleWallpaper() {
        wallpaperManager?.toggleWallpaper()
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
        print("🪟 AppDelegate: Opening dashboard window")
        if dashboardWindow == nil {
            print("🆕 AppDelegate: Creating new DashboardView")
            let dashboardView = DashboardView()
            let hostingController = NSHostingController(rootView: dashboardView)
            
            dashboardWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            dashboardWindow?.title = "Live Desktop"
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
    
    // MARK: - Image Cache Configuration
    private func configureImageCache() {
        
        // Configure memory cache (100MB)
        KingfisherManager.shared.cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
        
        // Configure disk cache (500MB)
        KingfisherManager.shared.cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024
        
        // Set cache expiration (7 days)
        KingfisherManager.shared.cache.diskStorage.config.expiration = .days(7)
        
        // Optimize for smooth scrolling with lazy loading
        KingfisherManager.shared.downloader.downloadTimeout = 10.0
        ImageCache.default.memoryStorage.config.countLimit = 200
        
        // Reduce processing queue for smoother performance
        KingfisherManager.shared.defaultOptions = [
            .processor(DownsamplingImageProcessor(size: CGSize(width: 400, height: 225))),
            .scaleFactor(NSScreen.main?.backingScaleFactor ?? 2.0),
            .cacheOriginalImage
        ]
        
    }
}
