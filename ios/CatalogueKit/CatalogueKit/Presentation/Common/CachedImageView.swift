import SwiftUI
import UIKit

/// Shows an image from `ImageLoader`: a spinner while loading, and a fallback icon if it fails.
struct CachedImageView: View {
    let url: URL
    let loader: ImageLoader

    private enum Phase {
        case loading
        case loaded(UIImage)
        case failed
    }

    @State private var phase: Phase = .loading

    var body: some View {
        Group {
            switch phase {
            case .loading:
                ProgressView()
            case .loaded(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            case .failed:
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
            }
        }
        .task(id: url) {
            if let image = await loader.image(for: url) {
                phase = .loaded(image)
            } else {
                phase = .failed
            }
        }
    }
}
