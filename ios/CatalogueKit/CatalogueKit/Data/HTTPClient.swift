import Foundation

nonisolated protocol HTTPClient: Sendable {
    func data(from url: URL) async throws -> Data
    /// Sends a JSON body with POST and returns the response body. Throws for non-2xx responses.
    func post(_ url: URL, body: Data) async throws -> Data
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
        return try await send(request)
    }

    func post(_ url: URL, body: Data) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.Network.requestTimeout
        return try await send(request)
    }

    /// Runs the request and checks the status. A request cancelled by its task is reported as `CancellationError`,
    /// not as a network failure, so callers can stop without showing an error or falling back to saved data.
    private func send(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        }
        guard let http = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        guard Constants.Network.successStatusRange.contains(http.statusCode) else {
            throw HTTPError.unexpectedStatus(http.statusCode)
        }
        return data
    }
}
