import SwiftUI
import AVKit
import AVFoundation

struct ActiveDisplayPreview: View {
    let video: VideoItem
    @ObservedObject private var downloadsService = DownloadsService.shared
    
    var body: some View {
        ZStack {
            // Video Player
            if let videoURL = URL(string: video.videoURL ?? "") {
                ActiveVideoPlayerView(videoURL: videoURL, videoId: video.id)
                    .cornerRadius(8)
            } else {
                // Fallback
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .cornerRadius(8)
            }
            
            // Download overlay
            VStack {
                HStack {
                    Spacer()
                    
                    // Download button or progress
                    if let progress = downloadsService.downloadProgress[video.id] {
                        if progress.isCompleted {
                            // Downloaded - no button
                            EmptyView()
                        } else {
                            // Downloading - show progress
                            CircularProgressView(progress: progress.progress)
                                .frame(width: 24, height: 24)
                        }
                    } else if downloadsService.isDownloaded(videoId: video.id) {
                        // Already downloaded - no button
                        EmptyView()
                    } else {
                        // Not downloaded - show download button
                        Button(action: {
                            downloadsService.downloadVideo(videoId: video.id, hdURL: video.videoURL ?? "")
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

struct ActiveVideoPlayerView: NSViewRepresentable {
    let videoURL: URL
    let videoId: String
    @ObservedObject private var downloadsService = DownloadsService.shared
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        
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
        
        // Set up looping notification
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            guard let player = player else { return }
            player.seek(to: CMTime.zero)
            player.play()
        }
        
        // Start playing
        player.play()
        
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        // Update player URL if local version becomes available
        if let player = nsView.player {
            let localURL = downloadsService.getLocalVideoURL(videoId: videoId) ?? videoURL
            if player.currentItem?.asset != AVURLAsset(url: localURL) {
                let newPlayer = AVPlayer(url: localURL)
                newPlayer.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
                newPlayer.isMuted = true
                newPlayer.volume = 0.0
                
                // Set up looping for the new player
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: newPlayer.currentItem,
                    queue: .main
                ) { [weak newPlayer] _ in
                    guard let player = newPlayer else { return }
                    player.seek(to: CMTime.zero)
                    player.play()
                }
                
                nsView.player = newPlayer
                newPlayer.play()
            }
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.white, lineWidth: 2)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
        }
    }
}
