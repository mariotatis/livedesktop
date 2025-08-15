import SwiftUI
import Kingfisher

struct CachedAsyncImage: View {
    let url: String?
    let placeholder: () -> AnyView
    let contentMode: SwiftUI.ContentMode
    
    init(
        url: String?,
        contentMode: SwiftUI.ContentMode = .fit,
        @ViewBuilder placeholder: @escaping () -> some View = { 
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
        }
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = { AnyView(placeholder()) }
    }
    
    var body: some View {
        if let urlString = url, let imageURL = URL(string: urlString) {
            KFImage(imageURL)
                .placeholder { placeholder() }
                .cacheMemoryOnly(false)
                .fade(duration: 0.0) // No fade for instant cached image display
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            placeholder()
        }
    }
}
