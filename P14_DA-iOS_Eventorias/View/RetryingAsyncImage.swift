import SwiftUI

struct RetryingAsyncImage: View {
    let url: URL
    @State private var retryCount = 0
    let maxRetries = 3
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                Color.gray.opacity(0.3)
                    .overlay(ProgressView())
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Color.gray.opacity(0.3)
                    .overlay(Image(systemName: "photo").foregroundColor(.gray))
                    .onAppear {
                        // Firebase Storage URLs sometimes take a second to propagate.
                        // Automatically retry up to `maxRetries` times with a delay.
                        if retryCount < maxRetries {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                retryCount += 1
                            }
                        }
                    }
            @unknown default:
                EmptyView()
            }
        }
        .id(retryCount) // Changing the ID forces AsyncImage to completely restart
    }
}
