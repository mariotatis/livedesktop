import Foundation
import Combine

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    func request<T: Codable>(
        endpoint: String,
        method: String = "GET",
        parameters: [String: Any]? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, Error> {
        guard let url = URL(string: APIConstants.baseURL + endpoint) else {
            print("❌ NetworkManager: Invalid URL - \(APIConstants.baseURL + endpoint)")
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add query parameters for GET requests
        if method == "GET", let parameters = parameters {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            if let urlWithParams = components?.url {
                request.url = urlWithParams
                print("🌐 NetworkManager: Making request to \(urlWithParams.absoluteString)")
            }
        } else {
            print("🌐 NetworkManager: Making request to \(url.absoluteString)")
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .handleEvents(
                receiveSubscription: { _ in
                    print("📡 NetworkManager: Starting request...")
                },
                receiveOutput: { data, response in
                    if let httpResponse = response as? HTTPURLResponse {
                        print("✅ NetworkManager: Response received - Status: \(httpResponse.statusCode), Data size: \(data.count) bytes")
                    }
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ NetworkManager: Request completed successfully")
                    case .failure(let error):
                        print("❌ NetworkManager: Request failed with error: \(error)")
                    }
                }
            )
            .map(\.data)
            .decode(type: responseType, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
