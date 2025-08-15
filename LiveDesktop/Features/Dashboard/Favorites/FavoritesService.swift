import Foundation
import Combine

class FavoritesService: ObservableObject {
    static let shared = FavoritesService()
    
    @Published var favoriteVideos: [VideoItem] = []
    
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "LiveDesktop_FavoriteVideos"
    
    private init() {
        loadFavorites()
        print("🎯 FavoritesService: Initialized with \(favoriteVideos.count) favorites")
    }
    
    private func loadFavorites() {
        if let data = userDefaults.data(forKey: favoritesKey),
           let savedFavorites = try? JSONDecoder().decode([VideoItem].self, from: data) {
            favoriteVideos = savedFavorites
        }
    }
    
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteVideos) {
            userDefaults.set(data, forKey: favoritesKey)
            print("💾 FavoritesService: Saved \(favoriteVideos.count) favorites to UserDefaults")
        }
    }
    
    func toggleFavorite(video: VideoItem) {
        if let index = favoriteVideos.firstIndex(where: { $0.id == video.id }) {
            favoriteVideos.remove(at: index)
            print("💔 FavoritesService: Removed favorite - \(video.id)")
        } else {
            favoriteVideos.append(video)
            print("❤️ FavoritesService: Added favorite - \(video.id)")
        }
        saveFavorites()
    }
    
    func isFavorite(videoId: String) -> Bool {
        return favoriteVideos.contains { $0.id == videoId }
    }
    
    func getFavoriteVideos() -> [VideoItem] {
        return favoriteVideos
    }
    
    func clearAllFavorites() {
        favoriteVideos.removeAll()
        saveFavorites()
        print("🗑️ FavoritesService: Cleared all favorites")
    }
}
