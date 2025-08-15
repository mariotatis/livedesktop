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
        // Initialized as singleton
    }
    
    func loadPopularVideos(page: Int = 1, reset: Bool = false) {
        guard !isLoading else { 
            return 
        }
        
        guard hasMorePages || reset else {
            return
        }
        
        if reset {
            currentPage = 1
            videos.removeAll()
            hasMorePages = true
        }
        
        isLoading = true
        
        let parameters = ["page": page]
        
        NetworkManager.shared.request(
            endpoint: APIConstants.Endpoints.popularVideos,
            parameters: parameters,
            responseType: PopularVideosResponse.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                // Filter for landscape videos only (width > height)
                let landscapeVideos = response.data.videos.filter { $0.width > $0.height }
                
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
            }
        )
        .store(in: &cancellables)
    }
    
    private var lastLoadTime: Date = Date.distantPast
    private let loadThrottleInterval: TimeInterval = 1.0 // 1 second throttle
    
    func loadNextPage() {
        let now = Date()
        guard hasMorePages && !isLoading else { 
            return 
        }
        
        // Throttle rapid pagination calls
        guard now.timeIntervalSince(lastLoadTime) >= loadThrottleInterval else {
            return
        }
        
        lastLoadTime = now
        loadPopularVideos(page: currentPage + 1)
    }
    
    func refresh() {
        loadPopularVideos(page: 1, reset: true)
    }
}
