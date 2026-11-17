import SwiftUI

@main
struct CatalogueKitApp: App {
    private let container: AppContainer?

    init() {
        container = try? AppContainer()
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                HomeView(
                    viewModel: container.homeViewModel,
                    search: container.homeSearchViewModel,
                    imageLoader: container.imageLoader,
                    makeCategoryViewModel: container.makeCategoryViewModel,
                    makeCategorySearchViewModel: container.makeCategorySearchViewModel
                )
            } else {
                Text(L10n.homeLoadFailed)
            }
        }
    }
}
