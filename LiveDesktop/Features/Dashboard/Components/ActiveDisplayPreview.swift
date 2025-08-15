import SwiftUI
import AVKit
import AVFoundation

struct ActiveDisplayPreview: View {
    let video: VideoItem
    @ObservedObject private var downloadsService = DownloadsService.shared
    @ObservedObject private var popularsService = PopularsService.shared
    
    var body: some View {
        ZStack {
            // Thumbnail background (always visible)
            CachedAsyncImage(url: video.imageURL, contentMode: .fill) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .cornerRadius(8)
            .clipped()
            
            // Video Player overlay (conditionally shown)
            if let videoURL = URL(string: video.videoURL ?? ""), 
               !downloadsService.isDownloading(videoId: video.id) {
                ActiveVideoPlayerView(videoURL: videoURL, videoId: video.id)
                    .cornerRadius(8)
                    .clipped()
                    .background(Color.clear)
            }
            
            // Download overlay
            ZStack {
                // Download Progress Bar (like VideoGrid)
                if downloadsService.isDownloading(videoId: video.id) {
                    VStack {
                        Spacer()
                        ProgressView(value: downloadsService.getDownloadProgress(videoId: video.id))
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                    }
                }
                
                // Action Buttons
                VStack {
                    HStack {
                        Spacer()
                        
                        // Download button (only show if not downloading and not downloaded)
                        if !downloadsService.isDownloading(videoId: video.id) && !downloadsService.isDownloaded(videoId: video.id) {
                            Button(action: {
                                // Get HD URL from PopularsService like VideoGrid does
                                print("🔍 ActiveDisplayPreview: Attempting download for video ID: \(video.id)")
                                print("🔍 ActiveDisplayPreview: PopularsService has \(popularsService.videos.count) videos")
                                
                                if let popularVideo = popularsService.videos.first(where: { String($0.id) == video.id }) {
                                    print("✅ ActiveDisplayPreview: Found video in PopularsService, HD URL: \(popularVideo.videoFileHd)")
                                    downloadsService.downloadVideo(videoId: video.id, hdURL: popularVideo.videoFileHd)
                                } else {
                                    print("❌ ActiveDisplayPreview: Video \(video.id) not found in PopularsService")
                                    print("🔍 ActiveDisplayPreview: Available video IDs: \(popularsService.videos.map { String($0.id) })")
                                }
                            }) {
                                Image(systemName: "arrow.down")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .medium))
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                        }
                    }
                    Spacer()
                }
                .padding(8)
            }
        }
    }
}

// Safe observer class that properly manages KVO
class SafePlayerObserver: NSObject {
    weak var playerView: AVPlayerView?
    weak var player: AVPlayer?
    private var isObserving = false
    
    init(playerView: AVPlayerView, player: AVPlayer) {
        self.playerView = playerView
        self.player = player
        super.init()
        setupObserver()
    }
    
    private func setupObserver() {
        guard let player = player, !isObserving else { return }
        
        player.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        isObserving = true
        
        // Setup looping notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
    }
    
    @objc private func playerDidFinishPlaying() {
        guard let player = player else { return }
        player.seek(to: CMTime.zero)
        player.play()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "status", 
              let player = self.player, 
              let playerView = self.playerView else { return }
        
        DispatchQueue.main.async {
            if player.status == .readyToPlay {
                playerView.alphaValue = 1.0
                player.play()
            }
        }
    }
    
    deinit {
        cleanup()
    }
    
    func cleanup() {
        guard isObserving, let player = player else { return }
        
        player.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
        isObserving = false
    }
}

struct ActiveVideoPlayerView: NSViewRepresentable {
    let videoURL: URL
    let videoId: String
    @ObservedObject private var downloadsService = DownloadsService.shared
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.clear.cgColor
        containerView.layer?.isOpaque = false
        
        let playerView = AVPlayerView()
        playerView.wantsLayer = true
        playerView.layer?.backgroundColor = NSColor.clear.cgColor
        playerView.layer?.isOpaque = false
        
        // Initially hide player until video is ready to avoid black box
        playerView.alphaValue = 0.0
        
        // Check if we have a local downloaded version first
        let localURL = downloadsService.getLocalVideoURL(videoId: videoId) ?? videoURL
        let player = AVPlayer(url: localURL)
        
        // Configure player for looping
        player.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        player.isMuted = true
        player.volume = 0.0
        
        // Hide all controls
        playerView.controlsStyle = .none
        playerView.showsFrameSteppingButtons = false
        playerView.showsFullScreenToggleButton = false
        playerView.showsSharingServiceButton = false
        playerView.allowsPictureInPicturePlayback = false
        
        // Set video gravity to fill the entire view without black bars
        playerView.videoGravity = .resizeAspectFill
        
        playerView.player = player
        
        // Add player view to container
        containerView.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        
        let observer = SafePlayerObserver(playerView: playerView, player: player)
        objc_setAssociatedObject(containerView, "observer", observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update the player when video changes
        guard let containerView = nsView as? NSView,
              let playerView = containerView.subviews.first as? AVPlayerView else { return }
        
        // Check if we need to update the video
        let localURL = downloadsService.getLocalVideoURL(videoId: videoId) ?? videoURL
        
        if playerView.player?.currentItem?.asset != AVURLAsset(url: localURL) {
            // Create new player with updated URL
            let newPlayer = AVPlayer(url: localURL)
            newPlayer.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
            newPlayer.isMuted = true
            newPlayer.volume = 0.0
            
            // Update player view
            playerView.player = newPlayer
            
            // Setup new observer
            let observer = SafePlayerObserver(playerView: playerView, player: newPlayer)
            objc_setAssociatedObject(containerView, "observer", observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
