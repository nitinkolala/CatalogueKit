import SwiftUI

/// Swipeable image gallery. A page indicator shows when there is more than one image.
/// Each image zooms with a pinch and returns to normal size when the pinch ends.
struct ProductGalleryView: View {
    let images: [URL]
    let productName: String
    let imageLoader: ImageLoader

    var body: some View {
        TabView {
            ForEach(Array(images.enumerated()), id: \.offset) { index, url in
                ZoomableImage(url: url, loader: imageLoader)
                    .padding(Constants.Home.cardPadding)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(L10n.productImageLabel(productName, index + 1, images.count))
                    .accessibilityAddTraits(.isImage)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .always : .never))
        .frame(height: Constants.Home.detailImageHeight)
    }
}

/// One gallery image. A pinch zooms it and the zoom stays after the fingers lift; a double tap resets it.
private struct ZoomableImage: View {
    let url: URL
    let loader: ImageLoader

    @State private var zoom: CGFloat = 1
    @GestureState private var pinch: CGFloat = 1

    var body: some View {
        CachedImageView(url: url, loader: loader, maxPoints: Constants.Images.detailMaxPoints)
            .scaleEffect(clamped(zoom * pinch))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .gesture(
                MagnifyGesture()
                    .updating($pinch) { value, state, _ in
                        state = value.magnification
                    }
                    .onEnded { value in
                        zoom = clamped(zoom * value.magnification)
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring) { zoom = 1 }
            }
    }

    private func clamped(_ value: CGFloat) -> CGFloat {
        min(max(value, 1), Constants.ProductPage.maxZoom)
    }
}
