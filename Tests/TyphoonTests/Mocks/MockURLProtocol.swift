//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

#if canImport(Darwin)
    import Foundation

    // MARK: - MockURLProtocol

    final class MockURLProtocol: URLProtocol, @unchecked Sendable {
        override class func canInit(with _: URLRequest) -> Bool {
            true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            let client = client
            Task {
                do {
                    let (response, data) = try await MockURLProtocolHandler.shared.callHandler()
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                } catch {
                    client?.urlProtocol(self, didFailWithError: error)
                }
            }
        }

        override func stopLoading() {}
    }
#endif
