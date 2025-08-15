import Foundation
import Combine

class PopularsService: ObservableObject {
    static let shared = PopularsService()
    
    @Published var videos: [PopularVideo] = []
    @Published var isLoading = false
    @Published var hasMorePages = true
    
    private var currentPage = 1
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        print("🎯 PopularsService: Initialized as singleton")
    }
    
    func loadPopularVideos(page: Int = 1, reset: Bool = false) {
        guard !isLoading else { 
            print("⚠️ PopularsService: Already loading, skipping request")
            return 
        }
        
        guard hasMorePages || reset else {
            print("⚠️ PopularsService: No more pages available")
            return
        }
        
        if reset {
            currentPage = 1
            videos.removeAll()
            hasMorePages = true
        }
        
        print("🚀 PopularsService: Starting to load videos for page \(page)")
        isLoading = true
        
        let parameters = ["page": page]
        print("📋 PopularsService: Parameters - \(parameters)")
        
        NetworkManager.shared.request(
            endpoint: APIConstants.Endpoints.popularVideos,
            parameters: parameters,
            responseType: PopularVideosResponse.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("Error loading popular videos: \(error)")
                }
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                print("🔍 PopularsService: API Response - page: \(response.data.page), videos: \(response.data.videos.count), total: \(response.data.totalResults), perPage: \(response.data.perPage)")
                
                // Filter for landscape videos only (width > height)
                let landscapeVideos = response.data.videos.filter { $0.width > $0.height }
                print("🎬 PopularsService: Filtered to \(landscapeVideos.count) landscape videos from \(response.data.videos.count) total")
                
                if reset {
                    self.videos = landscapeVideos
                    self.currentPage = response.data.page
                } else {
                    self.videos.append(contentsOf: landscapeVideos)
                    self.currentPage = response.data.page
                }
                
                // Check if there are more pages - use original response count for pagination logic
                let totalPages = Int(ceil(Double(response.data.totalResults) / Double(response.data.perPage)))
                self.hasMorePages = self.currentPage < totalPages
                
                print("🔍 PopularsService: Pagination check - currentPage: \(self.currentPage), totalPages: \(totalPages), hasMorePages: \(self.hasMorePages)")
                
                print("📊 PopularsService: Total landscape videos now: \(self.videos.count)")
                print("📊 PopularsService: Current page: \(self.currentPage), Total pages: \(totalPages)")
                print("📊 PopularsService: Original response: \(response.data.videos.count), Per page: \(response.data.perPage)")
                print("📊 PopularsService: Has more pages: \(self.hasMorePages)")
            }
        )
        .store(in: &cancellables)
    }
    
    func loadNextPage() {
        guard hasMorePages && !isLoading else { 
            print("⚠️ PopularsService: Cannot load next page - hasMorePages: \(hasMorePages), isLoading: \(isLoading)")
            return 
        }
        print("📄 PopularsService: Loading next page \(currentPage + 1)")
        loadPopularVideos(page: currentPage + 1)
    }
    
    func refresh() {
        loadPopularVideos(page: 1, reset: true)
    }
}
