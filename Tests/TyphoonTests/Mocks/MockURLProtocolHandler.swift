//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

#if canImport(Darwin)
    import Foundation

    // MARK: - MockURLProtocolHandler

    actor MockURLProtocolHandler {
        typealias Handler = @Sendable () throws -> (HTTPURLResponse, Data)

        static let shared = MockURLProtocolHandler()

        private var handler: Handler?

        func set(_ handler: Handler?) {
            self.handler = handler
        }

        func callHandler() throws -> (HTTPURLResponse, Data) {
            guard let handler else { throw URLError(.unknown) }
            return try handler()
        }
    }
#endif
