import SwiftUI
import AVKit
import AVFoundation

// Custom VideoPlayer without controls
struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .none
        playerView.showsFrameSteppingButtons = false
        playerView.showsFullScreenToggleButton = false
        playerView.showsSharingServiceButton = false
        playerView.actionPopUpButtonMenu = nil
        playerView.videoGravity = .resizeAspectFill
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}

struct HoverVideoPlayer: View {
    let imageURL: String?
    let videoURL: String?
    
    @State private var isHovering = false
    @State private var hoverTimer: Timer?
    @State private var player: AVPlayer?
    @State private var shouldShowVideo = false
    @State private var isVideoReady = false
    
    var body: some View {
        ZStack {
            // Thumbnail image (always visible as background)
            AsyncImageView(url: imageURL)
                .opacity(shouldShowVideo && isVideoReady ? 0.0 : 1.0)
            
            // Video player (shown on hover after delay)
            if shouldShowVideo, let player = player {
                VideoPlayerView(player: player)
                    .allowsHitTesting(false)
                    .opacity(isVideoReady ? 1.0 : 0.0)
                    .onAppear {
                        // Wait for video to be ready before playing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            player.play()
                            withAnimation(.easeInOut(duration: 0.4)) {
                                isVideoReady = true
                            }
                        }
                    }
                    .onDisappear {
                        player.pause()
                        player.seek(to: .zero)
                        isVideoReady = false
                    }
            }
        }
        .onHover { hovering in
            isHovering = hovering
            
            if hovering {
                // Start timer for 1 second delay
                hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                    if isHovering {
                        startVideoPlayback()
                    }
                }
            } else {
                // Cancel timer and stop video
                hoverTimer?.invalidate()
                hoverTimer = nil
                stopVideoPlayback()
            }
        }
    }
    
    private func startVideoPlayback() {
        guard let videoURL = videoURL, let url = URL(string: videoURL) else { return }
        
        if player == nil {
            player = AVPlayer(url: url)
            player?.isMuted = true // Mute to avoid audio conflicts
            player?.volume = 0.0
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            shouldShowVideo = true
        }
    }
    
    private func stopVideoPlayback() {
        withAnimation(.easeInOut(duration: 0.3)) {
            shouldShowVideo = false
            isVideoReady = false
        }
        
        player?.pause()
        player?.seek(to: .zero)
    }
}
