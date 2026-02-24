//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

#if canImport(Darwin)
    import Foundation

    public extension URLSession {
        /// Performs a data task with retry policy applied.
        ///
        /// - Parameters:
        ///   - request: The URL request to perform.
        ///   - strategy: The retry strategy to apply.
        ///   - onFailure: An optional closure called on each failure. Return `false` to stop retrying early.
        /// - Returns: A tuple of `(Data, URLResponse)`.
        func data(
            for request: URLRequest,
            retryPolicy strategy: RetryPolicyStrategy,
            onFailure: (@Sendable (Error) async -> Bool)? = nil
        ) async throws -> (Data, URLResponse) {
            try await RetryPolicyService(strategy: strategy).retry(
                strategy: nil,
                onFailure: onFailure
            ) {
                try await self.data(for: request)
            }
        }

        /// Performs a data task for a URL with retry policy applied.
        ///
        /// - Parameters:
        ///   - url: The URL to fetch.
        ///   - strategy: The retry strategy to apply.
        ///   - onFailure: An optional closure called on each failure. Return `false` to stop retrying early.
        /// - Returns: A tuple of `(Data, URLResponse)`.
        func data(
            from url: URL,
            retryPolicy strategy: RetryPolicyStrategy,
            onFailure: (@Sendable (Error) async -> Bool)? = nil
        ) async throws -> (Data, URLResponse) {
            try await RetryPolicyService(strategy: strategy).retry(
                strategy: nil,
                onFailure: onFailure
            ) {
                try await self.data(from: url)
            }
        }

        /// Uploads data for a request with retry policy applied.
        ///
        /// - Parameters:
        ///   - request: The URL request to use for the upload.
        ///   - bodyData: The data to upload.
        ///   - strategy: The retry strategy to apply.
        ///   - onFailure: An optional closure called on each failure. Return `false` to stop retrying early.
        /// - Returns: A tuple of `(Data, URLResponse)`.
        func upload(
            for request: URLRequest,
            from bodyData: Data,
            retryPolicy strategy: RetryPolicyStrategy,
            onFailure: (@Sendable (Error) async -> Bool)? = nil
        ) async throws -> (Data, URLResponse) {
            try await RetryPolicyService(strategy: strategy).retry(
                strategy: nil,
                onFailure: onFailure
            ) {
                try await self.upload(for: request, from: bodyData)
            }
        }

        /// Downloads a file for a request with retry policy applied.
        ///
        /// - Parameters:
        ///   - request: The URL request to use for the download.
        ///   - strategy: The retry strategy to apply.
        ///   - delegate: A delegate that receives life cycle and authentication challenge callbacks as the transfer progresses.
        ///   - onFailure: An optional closure called on each failure. Return `false` to stop retrying early.
        /// - Returns: A tuple of `(URL, URLResponse)` where `URL` is the temporary file location.
        @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
        func download(
            for request: URLRequest,
            retryPolicy strategy: RetryPolicyStrategy,
            delegate: (any URLSessionTaskDelegate)? = nil,
            onFailure: (@Sendable (Error) async -> Bool)? = nil
        ) async throws -> (URL, URLResponse) {
            try await RetryPolicyService(strategy: strategy).retry(
                strategy: nil,
                onFailure: onFailure
            ) {
                try await self.download(for: request, delegate: delegate)
            }
        }
    }
#endif
