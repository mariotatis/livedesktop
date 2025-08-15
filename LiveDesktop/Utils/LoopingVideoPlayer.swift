import SwiftUI
import AVKit
import AVFoundation

struct LoopingVideoPlayerView: NSViewRepresentable {
    let videoURL: URL
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        let player = AVPlayer(url: videoURL)
        
        // Configure player for looping
        player.actionAtItemEnd = .none
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
        
        // Set up looping notification
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: CMTime.zero)
            player.play()
        }
        
        // Start playing
        player.play()
        
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        // No updates needed
    }
}

struct LoopingVideoPlayer: View {
    let videoFileName: String
    
    var body: some View {
        if let videoURL = Bundle.main.url(forResource: videoFileName, withExtension: "mp4") {
            LoopingVideoPlayerView(videoURL: videoURL)
        } else {
            // Fallback if video not found
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    Text("Video Preview")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                )
        }
    }
}
