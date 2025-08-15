import SwiftUI

struct AsyncImageView: View {
    let url: String?
    let placeholder: String = "photo"
    
    var body: some View {
        AsyncImage(url: URL(string: url ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            }
        }
    }
}
