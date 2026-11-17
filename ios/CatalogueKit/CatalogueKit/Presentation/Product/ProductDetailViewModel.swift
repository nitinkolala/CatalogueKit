import Observation

/// Drives the product page. It starts with the product the customer tapped, so the content is on screen at once,
/// then reloads the latest copy. A failed reload keeps the content on screen and says what went wrong.
@MainActor
@Observable
final class ProductDetailViewModel {
    enum Phase: Equatable {
        case loaded
        case notFound
        case failed(ProductLoadError)
    }

    /// The product to show. Nil only when the product no longer exists.
    private(set) var product: Product?
    private(set) var phase: Phase = .loaded
    private(set) var isRefreshing = false

    private let productId: Int
    private let getProductDetail: GetProductDetailUseCase

    init(product: Product, getProductDetail: GetProductDetailUseCase) {
        self.product = product
        self.productId = product.id
        self.getProductDetail = getProductDetail
    }

    func load() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            product = try await getProductDetail.execute(id: productId)
            phase = .loaded
        } catch is CancellationError {
            return
        } catch let error as ProductLoadError {
            switch error {
            case .notFound:
                product = nil
                phase = .notFound
            case .offline, .service:
                phase = .failed(error)
            }
        } catch {
            phase = .failed(.service)
        }
    }
}

/// Decides when a description is long enough to collapse behind a "Show more" control.
nonisolated enum DescriptionLength {
    static func isLong(_ text: String) -> Bool {
        text.count > Constants.ProductPage.descriptionCollapseLength
    }
}
