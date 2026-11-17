import Foundation

/// Composition root: builds the dependency graph once for the app's lifetime.
@MainActor
final class AppContainer {
    let environment: AppEnvironment
    let imageLoader: ImageLoader
    let homeViewModel: HomeViewModel

    init(environment: AppEnvironment = .current) throws {
        self.environment = environment

        let httpClient = URLSessionHTTPClient()
        let remote = RemoteProductDataSource(client: httpClient, baseURL: environment.baseURL)
        let cache = ProductsDiskCache(fileURL: try ProductsDiskCache.defaultFileURL())
        let repository = FeaturedProductsRepository(remote: remote, cache: cache)

        self.imageLoader = ImageLoader(
            client: httpClient,
            diskDirectory: try ImageLoader.defaultDiskDirectory()
        )
        self.homeViewModel = HomeViewModel(
            getFeaturedProducts: DefaultGetFeaturedProductsUseCase(repository: repository)
        )
    }
}
