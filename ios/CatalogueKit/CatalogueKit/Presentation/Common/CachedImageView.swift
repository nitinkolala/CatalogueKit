import SwiftUI
import UIKit

/// Shows an image from `ImageLoader`: a spinner while loading, and a fallback icon if it fails.
/// The image is decoded no larger than `maxPoints` on its longest side, at the screen's scale.
struct CachedImageView: View {
    let url: URL
    let loader: ImageLoader
    var maxPoints: CGFloat = Constants.Images.cardMaxPoints

    @Environment(\.displayScale) private var displayScale

    private enum Phase {
        case loading
        case loaded(UIImage)
        case failed
    }

    @State private var phase: Phase = .loading

    private var maxPixelSize: Int {
        Int((maxPoints * displayScale).rounded(.up))
    }

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
        .task(id: ImageLoader.cacheKey(url: url, maxPixelSize: maxPixelSize)) {
            if let image = await loader.image(for: url, maxPixelSize: maxPixelSize) {
                phase = .loaded(image)
            } else {
                phase = .failed
            }
        }
    }
}
