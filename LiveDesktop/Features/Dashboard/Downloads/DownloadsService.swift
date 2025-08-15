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
    @Published var downloadProgress: [String: DownloadProgress] = [:]
    @Published var showDeleteMessage = false
    @Published var deleteMessage = ""
    
    private let userDefaults = UserDefaults.standard
    private let downloadedVideosKey = "LiveDesktop_DownloadedVideos"
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
        if let savedDownloads = userDefaults.array(forKey: downloadedVideosKey) as? [String] {
            downloadedVideoIds = Set(savedDownloads)
        }
    }
    
    private func saveDownloadedVideos() {
        userDefaults.set(Array(downloadedVideoIds), forKey: downloadedVideosKey)
        print("💾 DownloadsService: Saved \(downloadedVideoIds.count) downloads to UserDefaults")
    }
    
    // MARK: - Download Management
    func downloadVideo(videoId: String, hdURL: String) {
        guard !isDownloaded(videoId: videoId) && !isDownloading(videoId: videoId) else {
            print("⚠️ DownloadsService: Video \(videoId) already downloaded or downloading")
            return
        }
        
        guard !hdURL.isEmpty else {
            print("❌ DownloadsService: Empty URL for video \(videoId)")
            return
        }
        
        guard let url = URL(string: hdURL) else {
            print("❌ DownloadsService: Invalid URL for video \(videoId): '\(hdURL)'")
            return
        }
        
        print("📥 DownloadsService: Starting download for video \(videoId)")
        print("🔗 DownloadsService: URL: \(hdURL)")
        
        // Initialize progress
        DispatchQueue.main.async {
            self.downloadProgress[videoId] = DownloadProgress(videoId: videoId, progress: 0.0, isCompleted: false)
        }
        
        do {
            let task = urlSession.downloadTask(with: url)
            downloadTasks[videoId] = task
            task.resume()
            print("✅ DownloadsService: Download task created and resumed for video \(videoId)")
        } catch {
            print("❌ DownloadsService: Failed to create download task for video \(videoId): \(error)")
            DispatchQueue.main.async {
                self.downloadProgress.removeValue(forKey: videoId)
            }
        }
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
    
    func getDownloadedVideos(from allVideos: [PopularVideo]) -> [PopularVideo] {
        return allVideos.filter { downloadedVideoIds.contains(String($0.id)) }
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
