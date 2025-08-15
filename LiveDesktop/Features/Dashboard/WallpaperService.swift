import Foundation
import Combine
import Cocoa
import AVKit
import AVFoundation

class WallpaperService: ObservableObject {
    static let shared = WallpaperService()
    
    @Published var currentWallpaperVideoId: String? = nil
    @Published var isSettingWallpaper = false
    @Published var wallpaperMessage = ""
    @Published var showWallpaperMessage = false
    
    private let userDefaults = UserDefaults.standard
    private let wallpaperVideoKey = "LiveDesktop_WallpaperVideo"
    private let mirrorDisplaysKey = "LiveDesktop_MirrorDisplays"
    private let selectedDisplayKey = "LiveDesktop_SelectedDisplay"
    private let displayVideoMappingKey = "LiveDesktop_DisplayVideoMapping"
    
    private var wallpaperManager: WallpaperManager?
    private var downloadsService = DownloadsService.shared
    
    private init() {
        loadWallpaperSettings()
    }
    
    // MARK: - Persistence
    private func loadWallpaperSettings() {
        currentWallpaperVideoId = userDefaults.string(forKey: wallpaperVideoKey)
    }
    
    private func saveWallpaperSettings() {
        if let videoId = currentWallpaperVideoId {
            userDefaults.set(videoId, forKey: wallpaperVideoKey)
        } else {
            userDefaults.removeObject(forKey: wallpaperVideoKey)
        }
    }
    
    func saveMirrorDisplays(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: mirrorDisplaysKey)
    }
    
    func getMirrorDisplays() -> Bool {
        return userDefaults.bool(forKey: mirrorDisplaysKey)
    }
    
    func saveSelectedDisplay(_ displayName: String?) {
        if let displayName = displayName {
            userDefaults.set(displayName, forKey: selectedDisplayKey)
        } else {
            userDefaults.removeObject(forKey: selectedDisplayKey)
        }
    }
    
    func getSelectedDisplay() -> String? {
        return userDefaults.string(forKey: selectedDisplayKey)
    }
    
    // MARK: - Display-Video Mapping
    func saveVideoForDisplay(_ videoId: String, displayName: String) {
        var displayMapping = getDisplayVideoMapping()
        displayMapping[displayName] = videoId
        
        if let data = try? JSONEncoder().encode(displayMapping) {
            userDefaults.set(data, forKey: displayVideoMappingKey)
        }
    }
    
    func getVideoForDisplay(_ displayName: String) -> String? {
        let displayMapping = getDisplayVideoMapping()
        return displayMapping[displayName]
    }
    
    private func getDisplayVideoMapping() -> [String: String] {
        guard let data = userDefaults.data(forKey: displayVideoMappingKey),
              let mapping = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return mapping
    }
    
    // MARK: - Wallpaper Management
    func setLiveDesktop(
        video: VideoItem,
        selectedDisplay: String?,
        mirrorDisplays: Bool,
        wallpaperManager: WallpaperManager
    ) {
        self.wallpaperManager = wallpaperManager
        
        // Save settings
        currentWallpaperVideoId = video.id
        saveWallpaperSettings()
        saveMirrorDisplays(mirrorDisplays)
        saveSelectedDisplay(selectedDisplay)
        
        // Save video-display mapping
        if mirrorDisplays {
            // Save video for all displays when mirroring
            for displayName in DisplayManager.shared.getDisplayNames() {
                saveVideoForDisplay(video.id, displayName: displayName)
            }
        } else if let displayName = selectedDisplay {
            // Save video for specific display
            saveVideoForDisplay(video.id, displayName: displayName)
        }
        
        // Check if video is downloaded
        if downloadsService.isDownloaded(videoId: video.id) {
            // Use local video
            setWallpaperWithLocalVideo(video: video, selectedDisplay: selectedDisplay, mirrorDisplays: mirrorDisplays)
        } else {
            // Download first, then set wallpaper
            downloadAndSetWallpaper(video: video, selectedDisplay: selectedDisplay, mirrorDisplays: mirrorDisplays)
        }
    }
    
    private func downloadAndSetWallpaper(
        video: VideoItem,
        selectedDisplay: String?,
        mirrorDisplays: Bool
    ) {
        isSettingWallpaper = true
        showMessage("Downloading video for wallpaper...")
        
        // Get HD URL from PopularsService
        guard let popularVideo = PopularsService.shared.videos.first(where: { String($0.id) == video.id }) else {
            showMessage("Error: Video not found")
            isSettingWallpaper = false
            return
        }
        
        // Start download
        downloadsService.downloadVideo(video: video, hdURL: popularVideo.videoFileHd)
        
        // Monitor download progress
        monitorDownloadProgress(video: video, selectedDisplay: selectedDisplay, mirrorDisplays: mirrorDisplays)
    }
    
    private func monitorDownloadProgress(
        video: VideoItem,
        selectedDisplay: String?,
        mirrorDisplays: Bool
    ) {
        // Check download status periodically
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if let progress = self.downloadsService.downloadProgress[video.id] {
                if progress.isCompleted {
                    timer.invalidate()
                    // Download completed, set wallpaper
                    self.setWallpaperWithLocalVideo(video: video, selectedDisplay: selectedDisplay, mirrorDisplays: mirrorDisplays)
                }
            } else if self.downloadsService.isDownloaded(videoId: video.id) {
                timer.invalidate()
                // Download completed, set wallpaper
                self.setWallpaperWithLocalVideo(video: video, selectedDisplay: selectedDisplay, mirrorDisplays: mirrorDisplays)
            }
        }
    }
    
    private func setWallpaperWithLocalVideo(
        video: VideoItem,
        selectedDisplay: String?,
        mirrorDisplays: Bool
    ) {
        guard let localVideoURL = downloadsService.getLocalVideoURL(videoId: video.id) else {
            showMessage("Error: Local video file not found")
            isSettingWallpaper = false
            return
        }
        
        // Disable current wallpaper
        wallpaperManager?.disableWallpaper()
        
        if mirrorDisplays {
            // Set wallpaper on all displays
            setWallpaperOnAllDisplays(videoURL: localVideoURL)
        } else if let displayName = selectedDisplay {
            // Set wallpaper on specific display
            setWallpaperOnDisplay(videoURL: localVideoURL, displayName: displayName)
        } else {
            showMessage("Error: No display selected")
            isSettingWallpaper = false
            return
        }
        
        showMessage("Live Desktop set successfully!")
        isSettingWallpaper = false
    }
    
    private func setWallpaperOnAllDisplays(videoURL: URL) {
        // Create wallpaper for each connected screen
        for screen in DisplayManager.shared.getAllScreens() {
            createWallpaperForScreen(screen, videoURL: videoURL)
        }
    }
    
    private func setWallpaperOnDisplay(videoURL: URL, displayName: String) {
        guard let screen = DisplayManager.shared.getScreen(for: displayName) else {
            showMessage("Error: Display not found")
            isSettingWallpaper = false
            return
        }
        
        createWallpaperForScreen(screen, videoURL: videoURL)
    }
    
    private func createWallpaperForScreen(_ screen: NSScreen, videoURL: URL) {
        // Reuse WallpaperManager's logic but with custom video
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
        
        // Start playback
        player.play()
    }
    
    // MARK: - Helper Methods (copied from WallpaperManager)
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
    
    private func showMessage(_ message: String) {
        DispatchQueue.main.async {
            self.wallpaperMessage = message
            self.showWallpaperMessage = true
            
            // Hide message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showWallpaperMessage = false
            }
        }
    }
}
