import Foundation
import Combine

class SearchService: ObservableObject {
    static let shared = SearchService()
    
    @Published var searchResults: [PopularVideo] = []
    @Published var isSearching = false
    @Published var hasMorePages = true
    
    private var currentPage = 1
    private var currentQuery = ""
    private var cancellables = Set<AnyCancellable>()
    private var searchCancellable: AnyCancellable?
    
    private init() {
        // Initialized as singleton
    }
    
    func searchVideos(query: String, page: Int = 1, reset: Bool = false) {
        guard !query.isEmpty && query.count >= 3 else {
            clearSearchResults()
            return
        }
        
        guard !isSearching || reset else {
            return
        }
        
        guard hasMorePages || reset else {
            return
        }
        
        if reset {
            currentPage = 1
            searchResults.removeAll()
            hasMorePages = true
            currentQuery = query
        }
        
        isSearching = true
        
        let parameters: [String: Any] = [
            "query": query,
            "page": page
        ]
        
        NetworkManager.shared.request(
            endpoint: APIConstants.Endpoints.searchVideos,
            parameters: parameters,
            responseType: PopularVideosResponse.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isSearching = false
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                // Filter for landscape videos only (width > height)
                let landscapeVideos = response.data.videos.filter { $0.width > $0.height }
                
                if reset {
                    self.searchResults = landscapeVideos
                    self.currentPage = response.data.page
                } else {
                    self.searchResults.append(contentsOf: landscapeVideos)
                    self.currentPage = response.data.page
                }
                
                // Check if there are more pages
                let totalPages = Int(ceil(Double(response.data.totalResults) / Double(response.data.perPage)))
                self.hasMorePages = self.currentPage < totalPages
            }
        )
        .store(in: &cancellables)
    }
    
    func searchWithDebounce(query: String, debounceTime: TimeInterval = 0.5) {
        // Cancel previous search
        searchCancellable?.cancel()
        
        guard !query.isEmpty && query.count >= 3 else {
            clearSearchResults()
            return
        }
        
        searchCancellable = Just(query)
            .delay(for: .seconds(debounceTime), scheduler: DispatchQueue.main)
            .sink { [weak self] debouncedQuery in
                self?.searchVideos(query: debouncedQuery, reset: true)
            }
    }
    
    func loadNextPage() {
        guard hasMorePages && !isSearching && !currentQuery.isEmpty else {
            return
        }
        
        searchVideos(query: currentQuery, page: currentPage + 1)
    }
    
    func clearSearchResults() {
        searchResults.removeAll()
        currentQuery = ""
        hasMorePages = true
        currentPage = 1
        isSearching = false
        searchCancellable?.cancel()
    }
}
