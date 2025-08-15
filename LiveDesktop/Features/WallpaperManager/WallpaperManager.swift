import Cocoa
import AVKit
import AVFoundation
import Combine

class WallpaperManager: NSObject {
    private var windows: [NSWindow] = []
    private var players: [AVPlayer] = []
    private var isEnabled = false
    private var displayChangeObserver: AnyCancellable?
    
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
        guard let videoURL = Bundle.main.url(forResource: "video", withExtension: "mp4") else {
            print("Error: Video file not found in bundle")
            return
        }
        
        // Clean up any existing wallpapers
        cleanupWallpaper()
        
        // Create wallpaper for each connected screen using shared DisplayManager
        for screen in DisplayManager.shared.getAllScreens() {
            createWallpaperForScreen(screen, videoURL: videoURL)
        }
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
