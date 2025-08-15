import Cocoa
import AVKit
import AVFoundation
import Combine

class WallpaperManager: NSObject {
    private var windows: [NSWindow] = []
    private var players: [AVPlayer] = []
    private var isEnabled = false
    private var displayChangeObserver: AnyCancellable?
    
    private let userDefaults = UserDefaults.standard
    private let wallpaperVideoKey = "LiveDesktop_WallpaperVideo"
    private let displayVideoMappingKey = "LiveDesktop_DisplayVideoMapping"
    
    var isWallpaperEnabled: Bool {
        return isEnabled
    }
    
    override init() {
        super.init()
        setupDisplayChangeMonitoring()
    }
    
    private func setupDisplayChangeMonitoring() {
        // Listen to DisplayManager's display changes
        displayChangeObserver = DisplayManager.shared.$availableDisplays
            .dropFirst() // Skip initial value
            .sink { [weak self] _ in
                guard let self = self, self.isEnabled else { return }
                
                print("Display configuration changed - refreshing wallpapers")
                
                // Delay the refresh slightly to ensure display changes are fully processed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.cleanupWallpaper()
                    self.setupWallpaper()
                }
            }
    }
    
    func enableWallpaper() {
        guard !isEnabled else { return }
        isEnabled = true
        setupWallpaper()
    }
    
    func disableWallpaper() {
        guard isEnabled else { return }
        isEnabled = false
        cleanupWallpaper()
    }
    
    func toggleWallpaper() {
        if isEnabled {
            disableWallpaper()
        } else {
            enableWallpaper()
        }
    }
    
    private func setupWallpaper() {
        // Clean up any existing wallpapers
        cleanupWallpaper()
        
        // Create wallpaper for each connected screen with display-specific video
        for display in DisplayManager.shared.availableDisplays {
            let videoURL = getWallpaperVideoURL(for: display.name)
            createWallpaperForScreen(display.screen, videoURL: videoURL)
        }
    }
    
    private func getWallpaperVideoURL(for displayName: String) -> URL {
        // Check if there's a saved video ID for this specific display
        if let videoId = getVideoForDisplay(displayName) {
            if let localVideoURL = getLocalVideoURL(for: videoId) {
                print("Using saved wallpaper video for \(displayName): \(videoId)")
                return localVideoURL
            } else {
                print("Saved wallpaper video for \(displayName) not found locally, using default")
            }
        }
        
        // Fallback to global saved video
        if let savedVideoId = userDefaults.string(forKey: wallpaperVideoKey) {
            if let localVideoURL = getLocalVideoURL(for: savedVideoId) {
                print("Using global saved wallpaper video: \(savedVideoId)")
                return localVideoURL
            }
        }
        
        // Final fallback to default bundle video
        guard let defaultVideoURL = Bundle.main.url(forResource: "video", withExtension: "mp4") else {
            fatalError("Default video file not found in bundle")
        }
        
        return defaultVideoURL
    }
    
    private func getVideoForDisplay(_ displayName: String) -> String? {
        guard let data = userDefaults.data(forKey: displayVideoMappingKey),
              let mapping = try? JSONDecoder().decode([String: String].self, from: data) else {
            return nil
        }
        return mapping[displayName]
    }
    
    private func getLocalVideoURL(for videoId: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let downloadsPath = documentsPath.appendingPathComponent("Downloads", isDirectory: true)
        let videoFileURL = downloadsPath.appendingPathComponent("\(videoId).mp4")
        
        return FileManager.default.fileExists(atPath: videoFileURL.path) ? videoFileURL : nil
    }
    
    private func createWallpaperForScreen(_ screen: NSScreen, videoURL: URL) {
        let screenFrame = screen.frame
        
        // Create borderless window for this screen
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        configureWindow(window)
        
        // Create video player for this screen
        let player = createVideoPlayer(for: videoURL)
        let playerView = createPlayerView(for: player, frame: screenFrame)
        
        window.contentView = playerView
        window.orderFront(nil)
        
        // Setup video looping
        setupVideoLooping(for: player)
        
        // Store references
        windows.append(window)
        players.append(player)
        
        // Start playback
        player.play()
    }
    
    private func configureWindow(_ window: NSWindow) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) - 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.ignoresMouseEvents = true
    }
    
    private func createVideoPlayer(for videoURL: URL) -> AVPlayer {
        let player = AVPlayer(url: videoURL)
        
        // Disable external playback to avoid routing issues
        player.allowsExternalPlayback = false
        
        // Mute audio to avoid multiple audio streams and routing warnings
        player.isMuted = true
        player.volume = 0.0
        
        // Prevent automatic pause when app loses focus
        player.automaticallyWaitsToMinimizeStalling = false
        player.preventsDisplaySleepDuringVideoPlayback = false
        
        return player
    }
    
    private func createPlayerView(for player: AVPlayer, frame: NSRect) -> AVPlayerView {
        let playerView = AVPlayerView(frame: NSRect(origin: .zero, size: frame.size))
        playerView.player = player
        playerView.controlsStyle = .none
        playerView.videoGravity = .resizeAspectFill
        playerView.showsFullScreenToggleButton = false
        playerView.showsSharingServiceButton = false
        playerView.showsFrameSteppingButtons = false
        
        return playerView
    }
    
    private func setupVideoLooping(for player: AVPlayer) {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            guard let player = player else { return }
            player.seek(to: .zero) { _ in
                player.play()
            }
        }
    }
    
    private func cleanupWallpaper() {
        // Stop and cleanup all players
        for player in players {
            player.pause()
            NotificationCenter.default.removeObserver(
                self, 
                name: .AVPlayerItemDidPlayToEndTime, 
                object: player.currentItem
            )
        }
        
        // Hide and cleanup all windows
        for window in windows {
            window.orderOut(nil)
        }
        
        // Clear references
        players.removeAll()
        windows.removeAll()
    }
    
    deinit {
        displayChangeObserver?.cancel()
        cleanupWallpaper()
    }
}
