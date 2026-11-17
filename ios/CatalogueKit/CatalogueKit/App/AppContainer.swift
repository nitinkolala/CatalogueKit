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
    let makeProductDetailViewModel: (Product) -> ProductDetailViewModel
    let makeEnquiryViewModel: (Product) -> EnquiryViewModel

    init(environment: AppEnvironment = .current) throws {
        self.environment = environment

        let httpClient = URLSessionHTTPClient()
        let baseURL = environment.baseURL
        let remote = RemoteProductDataSource(client: httpClient, baseURL: baseURL)

        // Every cache lives in a folder for this backend only. Files from before that split are removed.
        CacheLocation.removeLegacyFiles()
        let cacheDirectory = try CacheLocation.directory(for: environment, baseURL: baseURL)
        let cache = ProductsDiskCache(fileURL: cacheDirectory.appending(path: Constants.Cache.productsFileName))
        let repository = FeaturedProductsRepository(remote: remote, cache: cache)
        let categoryRepository = CachingCategoryRepository(
            remote: RemoteCategoryRepository(remote: remote),
            categoriesCache: KeyedDiskCache(
                fileURL: cacheDirectory.appending(path: Constants.Cache.categoriesFileName)
            ),
            productsCache: KeyedDiskCache(
                fileURL: cacheDirectory.appending(path: Constants.Cache.categoryProductsFileName)
            )
        )

        let getCategoryProducts = DefaultGetCategoryProductsUseCase(repository: categoryRepository)
        let searchUseCase = DefaultSearchProductsUseCase(repository: RemoteProductSearchRepository(remote: remote))
        let recents = UserDefaultsRecentSearchesStore(defaults: .standard, key: Constants.Search.recentSearchesKey)
        let connectivity = NetworkConnectivityMonitor()

        self.imageLoader = ImageLoader(
            client: httpClient,
            diskDirectory: try CacheLocation.subdirectory(Constants.Cache.imagesFolderName, in: cacheDirectory)
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
        let getProductDetail = DefaultGetProductDetailUseCase(
            repository: RemoteProductDetailRepository(remote: remote)
        )
        let submitEnquiry = DefaultSubmitEnquiryUseCase(
            repository: RemoteEnquiryRepository(client: httpClient, baseURL: environment.baseURL)
        )
        self.makeEnquiryViewModel = { product in
            EnquiryViewModel(product: product, submitUseCase: submitEnquiry)
        }
        self.makeProductDetailViewModel = { product in
            ProductDetailViewModel(product: product, getProductDetail: getProductDetail)
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
