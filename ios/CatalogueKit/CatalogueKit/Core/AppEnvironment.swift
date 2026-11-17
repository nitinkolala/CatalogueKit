import Foundation

/// Backend environments. The active one is chosen per run: the `APP_ENVIRONMENT`
/// scheme variable wins, otherwise Debug builds use `develop` and Release builds use `production`.
nonisolated enum AppEnvironment: String, CaseIterable, Sendable {
    case staging
    case develop
    case production

    static let selectionVariable = "APP_ENVIRONMENT"
    /// Optional override for local development, e.g. `http://localhost:3100`.
    static let baseURLOverrideVariable = "API_BASE_URL"

    /// Placeholder hosts for staging and production. Replace them with the client's real endpoints.
    var baseURL: URL {
        if let override = ProcessInfo.processInfo.environment[Self.baseURLOverrideVariable],
           let url = URL(string: override), url.scheme != nil {
            return url
        }
        let raw: String
        switch self {
        case .staging: raw = "https://staging.api.example.com"
        case .develop: raw = "http://localhost:3000"
        case .production: raw = "https://api.example.com"
        }
        guard let url = URL(string: raw) else {
            preconditionFailure("Invalid base URL for \(rawValue): \(raw)")
        }
        return url
    }

    static var current: AppEnvironment {
        if let raw = ProcessInfo.processInfo.environment[selectionVariable],
           let environment = AppEnvironment(rawValue: raw) {
            return environment
        }
        #if DEBUG
        return .develop
        #else
        return .production
        #endif
    }
}
