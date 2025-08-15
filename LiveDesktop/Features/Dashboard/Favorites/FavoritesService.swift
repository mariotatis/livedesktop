import Foundation
import Combine

class FavoritesService: ObservableObject {
    static let shared = FavoritesService()
    
    @Published var favoriteVideoIds: Set<String> = []
    
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "LiveDesktop_FavoriteVideos"
    
    private init() {
        loadFavorites()
        print("🎯 FavoritesService: Initialized with \(favoriteVideoIds.count) favorites")
    }
    
    private func loadFavorites() {
        if let savedFavorites = userDefaults.array(forKey: favoritesKey) as? [String] {
            favoriteVideoIds = Set(savedFavorites)
        }
    }
    
    private func saveFavorites() {
        userDefaults.set(Array(favoriteVideoIds), forKey: favoritesKey)
        print("💾 FavoritesService: Saved \(favoriteVideoIds.count) favorites to UserDefaults")
    }
    
    func toggleFavorite(videoId: String) {
        if favoriteVideoIds.contains(videoId) {
            favoriteVideoIds.remove(videoId)
            print("💔 FavoritesService: Removed favorite - \(videoId)")
        } else {
            favoriteVideoIds.insert(videoId)
            print("❤️ FavoritesService: Added favorite - \(videoId)")
        }
        saveFavorites()
    }
    
    func isFavorite(videoId: String) -> Bool {
        return favoriteVideoIds.contains(videoId)
    }
    
    func getFavoriteVideos(from allVideos: [PopularVideo]) -> [PopularVideo] {
        return allVideos.filter { favoriteVideoIds.contains(String($0.id)) }
    }
    
    func clearAllFavorites() {
        favoriteVideoIds.removeAll()
        saveFavorites()
        print("🗑️ FavoritesService: Cleared all favorites")
    }
}
