import Foundation
import Combine

class PopularsService: ObservableObject {
    @Published var videos: [PopularVideo] = []
    @Published var isLoading = false
    @Published var hasMorePages = true
    
    private var currentPage = 1
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("🎯 PopularsService: Initialized")
    }
    
    func loadPopularVideos(page: Int = 1, reset: Bool = false) {
        guard !isLoading else { 
            print("⚠️ PopularsService: Already loading, skipping request")
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
                
                if reset {
                    self.videos = response.data.videos
                } else {
                    self.videos.append(contentsOf: response.data.videos)
                }
                
                self.currentPage = response.data.page
                
                // Check if there are more pages
                let totalPages = Int(ceil(Double(response.data.totalResults) / Double(response.data.perPage)))
                self.hasMorePages = self.currentPage < totalPages
                
                print("Loaded \(response.data.videos.count) videos for page \(response.data.page)")
            }
        )
        .store(in: &cancellables)
    }
    
    func loadNextPage() {
        guard hasMorePages && !isLoading else { return }
        loadPopularVideos(page: currentPage + 1)
    }
    
    func refresh() {
        loadPopularVideos(page: 1, reset: true)
    }
}
