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
                HomeView(viewModel: container.homeViewModel, imageLoader: container.imageLoader)
            } else {
                Text(L10n.homeLoadFailed)
            }
        }
    }
}
