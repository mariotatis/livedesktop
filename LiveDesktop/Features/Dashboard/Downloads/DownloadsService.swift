import Foundation
import Combine

struct DownloadProgress {
    let videoId: String
    let progress: Double // 0.0 to 1.0
    let isCompleted: Bool
}

class DownloadsService: NSObject, ObservableObject {
    static let shared = DownloadsService()
    
    @Published var downloadedVideoIds: Set<String> = []
    @Published var downloadedVideos: [VideoItem] = []
    @Published var downloadProgress: [String: DownloadProgress] = [:]
    @Published var showDeleteMessage = false
    @Published var deleteMessage = ""
    
    private let userDefaults = UserDefaults.standard
    private let downloadedVideosKey = "LiveDesktop_DownloadedVideos"
    private let downloadedVideosDataKey = "LiveDesktop_DownloadedVideosData"
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 300.0
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }()
    
    override private init() {
        super.init()
        loadDownloadedVideos()
        print("🎯 DownloadsService: Initialized with \(downloadedVideoIds.count) downloaded videos")
    }
    
    // MARK: - Persistence
    private func loadDownloadedVideos() {
        // Load video IDs (for backward compatibility)
        if let savedDownloads = userDefaults.array(forKey: downloadedVideosKey) as? [String] {
            downloadedVideoIds = Set(savedDownloads)
        }
        
        // Load complete video data
        if let data = userDefaults.data(forKey: downloadedVideosDataKey),
           let savedVideos = try? JSONDecoder().decode([VideoItem].self, from: data) {
            downloadedVideos = savedVideos
        }
    }
    
    private func saveDownloadedVideos() {
        userDefaults.set(Array(downloadedVideoIds), forKey: downloadedVideosKey)
        
        if let data = try? JSONEncoder().encode(downloadedVideos) {
            userDefaults.set(data, forKey: downloadedVideosDataKey)
        }
        
        print("💾 DownloadsService: Saved \(downloadedVideoIds.count) downloaded videos to UserDefaults")
    }
    
    // MARK: - Download Management
    func downloadVideo(video: VideoItem, hdURL: String) {
        guard !isDownloaded(videoId: video.id) && !isDownloading(videoId: video.id) else {
            print("⚠️ DownloadsService: Video \(video.id) already downloaded or downloading")
            return
        }
        
        guard !hdURL.isEmpty else {
            print("❌ DownloadsService: Empty URL for video \(video.id)")
            return
        }
        
        guard let url = URL(string: hdURL) else {
            print("❌ DownloadsService: Invalid URL for video \(video.id): '\(hdURL)'")
            return
        }
        
        print("🚀 DownloadsService: Starting download for video \(video.id)")
        print("🔗 DownloadsService: HD URL: \(hdURL)")
        
        // Create download progress entry
        downloadProgress[video.id] = DownloadProgress(videoId: video.id, progress: 0.0, isCompleted: false)
        
        // Store video data for later use
        if !downloadedVideos.contains(where: { $0.id == video.id }) {
            var updatedVideo = video
            // Update with HD URL for future reference
            updatedVideo = VideoItem(
                id: video.id,
                title: video.title,
                author: video.author,
                category: video.category,
                imageURL: video.imageURL,
                videoURL: video.videoURL,
                videoURLHD: hdURL
            )
            downloadedVideos.append(updatedVideo)
        }
        
        // Start download task
        let downloadTask = urlSession.downloadTask(with: url)
        downloadTasks[video.id] = downloadTask
        downloadTask.resume()
    }
    
    func deleteVideo(videoId: String) {
        guard isDownloaded(videoId: videoId) else { return }
        
        let fileURL = getVideoFileURL(videoId: videoId)
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("🗑️ DownloadsService: Deleted video file for \(videoId)")
            }
            
            DispatchQueue.main.async {
                self.downloadedVideoIds.remove(videoId)
                self.downloadedVideos.removeAll { $0.id == videoId }
                self.downloadProgress.removeValue(forKey: videoId)
                self.saveDownloadedVideos()
                
                // Show delete message
                self.deleteMessage = "Video deleted successfully"
                self.showDeleteMessage = true
                
                // Hide message after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.showDeleteMessage = false
                }
            }
        } catch {
            print("❌ DownloadsService: Failed to delete video \(videoId): \(error)")
        }
    }
    
    // MARK: - Status Checks
    func isDownloaded(videoId: String) -> Bool {
        return downloadedVideoIds.contains(videoId)
    }
    
    func isDownloading(videoId: String) -> Bool {
        return downloadProgress[videoId]?.isCompleted == false
    }
    
    func getDownloadProgress(videoId: String) -> Double {
        return downloadProgress[videoId]?.progress ?? 0.0
    }
    
    func getDownloadedVideos() -> [VideoItem] {
        return downloadedVideos
    }
    
    // MARK: - File Management
    private func getDownloadsDirectory() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let downloadsPath = documentsPath.appendingPathComponent("Downloads", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: downloadsPath.path) {
            try? FileManager.default.createDirectory(at: downloadsPath, withIntermediateDirectories: true)
        }
        
        return downloadsPath
    }
    
    private func getVideoFileURL(videoId: String) -> URL {
        return getDownloadsDirectory().appendingPathComponent("\(videoId).mp4")
    }
    
    func getLocalVideoURL(videoId: String) -> URL? {
        guard isDownloaded(videoId: videoId) else { return nil }
        let fileURL = getVideoFileURL(videoId: videoId)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
}

// MARK: - URLSessionDownloadDelegate
extension DownloadsService: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        guard let videoId = downloadTasks.first(where: { $0.value == downloadTask })?.key else { 
            print("⚠️ DownloadsService: Could not find videoId for download task in progress callback")
            return 
        }
        
        guard totalBytesExpectedToWrite > 0 else {
            print("⚠️ DownloadsService: Invalid totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
            return
        }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        DispatchQueue.main.async {
            self.downloadProgress[videoId] = DownloadProgress(videoId: videoId, progress: progress, isCompleted: false)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let videoId = downloadTasks.first(where: { $0.value == downloadTask })?.key else { return }
        
        let destinationURL = getVideoFileURL(videoId: videoId)
        
        do {
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Move downloaded file to destination
            try FileManager.default.moveItem(at: location, to: destinationURL)
            
            DispatchQueue.main.async {
                self.downloadedVideoIds.insert(videoId)
                self.downloadProgress[videoId] = DownloadProgress(videoId: videoId, progress: 1.0, isCompleted: true)
                self.downloadTasks.removeValue(forKey: videoId)
                self.saveDownloadedVideos()
                
                print("✅ DownloadsService: Successfully downloaded video \(videoId)")
            }
        } catch {
            print("❌ DownloadsService: Failed to save downloaded video \(videoId): \(error)")
            DispatchQueue.main.async {
                self.downloadProgress.removeValue(forKey: videoId)
                self.downloadTasks.removeValue(forKey: videoId)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let videoId = downloadTasks.first(where: { $0.value == task })?.key else { return }
        
        if let error = error {
            print("❌ DownloadsService: Download failed for video \(videoId): \(error)")
            DispatchQueue.main.async {
                self.downloadProgress.removeValue(forKey: videoId)
                self.downloadTasks.removeValue(forKey: videoId)
            }
        }
    }
}
