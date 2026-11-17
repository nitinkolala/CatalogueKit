import Foundation

nonisolated protocol HTTPClient: Sendable {
    func data(from url: URL) async throws -> Data
}

nonisolated enum HTTPError: Error, Equatable {
    case unexpectedStatus(Int)
    case invalidResponse
}

nonisolated struct URLSessionHTTPClient: HTTPClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = Constants.Network.requestTimeout
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        guard Constants.Network.successStatusRange.contains(http.statusCode) else {
            throw HTTPError.unexpectedStatus(http.statusCode)
        }
        return data
    }
}
