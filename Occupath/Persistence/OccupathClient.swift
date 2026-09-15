import Foundation

/// Role: Persistence. Typed transport failures. This product has no remote catalog.
enum OccupathClientError: Error, Equatable, Sendable {
    case notFound
    case decoding
    case transport
    case cancelled
    case invalidResponse
}

/// Role: Persistence. Sends one HTTP request. Injected so tests never hit the network.
protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Persistence. URLSession-backed transport with a 15 s timeout and the app User-Agent.
struct URLSessionTransport: HTTPTransport {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": OccupathClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Persistence. Accepts a JSON number or a numeric string. Missing values stay nil.
struct FlexibleDouble: Sendable, Equatable {
    var value: Double?
}

extension FlexibleDouble: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let number = try? container.decode(Double.self) {
            value = number
            return
        }
        if let number = try? container.decode(Int.self) {
            value = Double(number)
            return
        }
        if let text = try? container.decode(String.self) {
            value = Double(text)
            return
        }
        value = nil
    }
}

/// Role: Persistence. Owns URLSession. Offline desk; this is the transport seam only.
actor OccupathClient {
    static let userAgent = "Occupath/1.0 (iOS; +https://occupath.pro)"

    private let transport: any HTTPTransport

    init(transport: any HTTPTransport) {
        self.transport = transport
    }

    init() {
        self.transport = URLSessionTransport()
    }

    func getJSON<DTO: Decodable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let data = try await fetch(makeRequest(url: url))
        do {
            return try JSONDecoder().decode(DTO.self, from: data)
        } catch is CancellationError {
            throw OccupathClientError.cancelled
        } catch {
            throw OccupathClientError.decoding
        }
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let error as OccupathClientError {
            throw error
        } catch is CancellationError {
            throw OccupathClientError.cancelled
        } catch {
            if isCancelled(error) {
                throw OccupathClientError.cancelled
            }
            guard isTransient(error) else { throw OccupathClientError.transport }
            do {
                return try await send(request)
            } catch let error as OccupathClientError {
                throw error
            } catch is CancellationError {
                throw OccupathClientError.cancelled
            } catch {
                if isCancelled(error) { throw OccupathClientError.cancelled }
                throw OccupathClientError.transport
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await transport.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OccupathClientError.invalidResponse
        }
        if http.statusCode == 404 {
            throw OccupathClientError.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw OccupathClientError.transport
        }
        return data
    }
}

func isTransient(_ error: Error) -> Bool {
    guard let urlError = error as? URLError else { return false }
    switch urlError.code {
    case .timedOut, .networkConnectionLost, .notConnectedToInternet,
         .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
        return true
    default:
        return false
    }
}

func isCancelled(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    return (error as? URLError)?.code == .cancelled
}
