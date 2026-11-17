import Foundation

/// Composition root: builds the dependency graph once for the app's lifetime.
@MainActor
final class AppContainer {
    let environment: AppEnvironment
    let imageLoader: ImageLoader
    let homeViewModel: HomeViewModel
    let homeSearchViewModel: ProductSearchViewModel
    let makeCategoryViewModel: (ProductCategory) -> CategoryViewModel
    let makeCategorySearchViewModel: (ProductCategory) -> ProductSearchViewModel

    init(environment: AppEnvironment = .current) throws {
        self.environment = environment

        let httpClient = URLSessionHTTPClient()
        let remote = RemoteProductDataSource(client: httpClient, baseURL: environment.baseURL)
        let cache = ProductsDiskCache(fileURL: try ProductsDiskCache.defaultFileURL())
        let repository = FeaturedProductsRepository(remote: remote, cache: cache)
        let categoryRepository = RemoteCategoryRepository(remote: remote)

        let getCategoryProducts = DefaultGetCategoryProductsUseCase(repository: categoryRepository)
        let searchUseCase = DefaultSearchProductsUseCase(repository: RemoteProductSearchRepository(remote: remote))
        let recents = UserDefaultsRecentSearchesStore(defaults: .standard, key: Constants.Search.recentSearchesKey)
        let connectivity = NetworkConnectivityMonitor()

        self.imageLoader = ImageLoader(
            client: httpClient,
            diskDirectory: try ImageLoader.defaultDiskDirectory()
        )
        self.homeViewModel = HomeViewModel(
            getFeaturedProducts: DefaultGetFeaturedProductsUseCase(repository: repository),
            getCategories: DefaultGetCategoriesUseCase(repository: categoryRepository)
        )
        self.homeSearchViewModel = ProductSearchViewModel(
            scope: nil,
            search: searchUseCase,
            recents: recents,
            connectivity: connectivity
        )
        self.makeCategoryViewModel = { category in
            CategoryViewModel(category: category, getCategoryProducts: getCategoryProducts)
        }
        self.makeCategorySearchViewModel = { category in
            ProductSearchViewModel(
                scope: category,
                search: searchUseCase,
                recents: recents,
                connectivity: connectivity
            )
        }
    }
}
