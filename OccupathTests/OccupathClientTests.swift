import XCTest
@testable import Occupath

private struct ProbeDTO: Decodable {
    var energy: FlexibleDouble
}

private actor ScriptedTransport: HTTPTransport {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class OccupathClientTests: XCTestCase {
    private let url = URL(string: "https://occupath.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let transport = ScriptedTransport(results: [
            .success((Data("{\"energy\":1}".utf8), http(200))),
        ])
        let client = OccupathClient(transport: transport)
        _ = try await client.getJSON(ProbeDTO.self, from: url)
        let request = await transport.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), OccupathClient.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(OccupathClient.userAgent, "Occupath/1.0 (iOS; +https://occupath.pro)")
    }

    func test_retriesTransientTransportOnce() async throws {
        let transport = ScriptedTransport(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"energy\":\"4.5\"}".utf8), http(200))),
        ])
        let client = OccupathClient(transport: transport)
        let dto = try await client.getJSON(ProbeDTO.self, from: url)
        XCTAssertEqual(dto.energy.value, 4.5)
        let count = await transport.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let transport = ScriptedTransport(results: [
            .success((Data(), http(404))),
            .success((Data("{\"energy\":1}".utf8), http(200))),
        ])
        let client = OccupathClient(transport: transport)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? OccupathClientError, .notFound)
        }
        let count = await transport.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsDecodingError() async {
        let transport = ScriptedTransport(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let client = OccupathClient(transport: transport)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected decoding")
        } catch {
            XCTAssertEqual(error as? OccupathClientError, .decoding)
        }
    }

    func test_flexibleDoubleAcceptsNumberAndString() throws {
        let number = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"energy\":12.5}".utf8))
        let string = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"energy\":\"12.5\"}".utf8))
        let missing = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"energy\":null}".utf8))
        XCTAssertEqual(number.energy.value, 12.5)
        XCTAssertEqual(string.energy.value, 12.5)
        XCTAssertNil(missing.energy.value)
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
}
