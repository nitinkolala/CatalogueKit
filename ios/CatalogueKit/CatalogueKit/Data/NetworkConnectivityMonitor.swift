import Foundation
import Network

/// Uses NWPathMonitor. Each call to `waitUntilOnline` watches the path until it is satisfied, then stops watching.
nonisolated struct NetworkConnectivityMonitor: ConnectivityMonitor {
    func waitUntilOnline() async {
        let statuses = AsyncStream<NWPath.Status> { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                continuation.yield(path.status)
            }
            continuation.onTermination = { _ in
                monitor.cancel()
            }
            monitor.start(queue: DispatchQueue(label: "CatalogueKit.connectivity"))
        }
        for await status in statuses where status == .satisfied {
            return
        }
    }
}
