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
    private var hasRefreshed = false

    init(product: Product, getProductDetail: GetProductDetailUseCase) {
        self.product = product
        self.productId = product.id
        self.getProductDetail = getProductDetail
    }

    /// Called when the page appears. Fetches the latest copy once per visit, and again only if that failed.
    /// Coming back from the Enquiry form keeps what is on screen.
    func loadIfNeeded() async {
        guard !hasRefreshed, !isRefreshing, phase != .notFound else { return }
        await load()
    }

    /// Fetches the latest copy. Used for the first load, pull to refresh and Retry.
    func load() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            product = try await getProductDetail.execute(id: productId)
            phase = .loaded
            hasRefreshed = true
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
