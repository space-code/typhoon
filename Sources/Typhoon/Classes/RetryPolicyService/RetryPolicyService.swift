//
// Typhoon
// Copyright © 2024 Space Code. All rights reserved.
//

import Foundation

// MARK: - RetryPolicyService

/// A class that defines a service for retry policies
public final class RetryPolicyService {
    // MARK: Private

    /// The strategy defining the behavior of the retry policy.
    private let strategy: RetryPolicyStrategy

    // MARK: Initialization

    /// Creates a new `RetryPolicyService` instance.
    ///
    /// - Parameter strategy: The strategy defining the behavior of the retry policy.
    public init(strategy: RetryPolicyStrategy) {
        self.strategy = strategy
    }
}

// MARK: IRetryPolicyService

extension RetryPolicyService: IRetryPolicyService {
    public func retry<T>(
        strategy: RetryPolicyStrategy?,
        onFailure: (@Sendable (Error) async -> Void)?,
        _ closure: @Sendable () async throws -> T
    ) async throws -> T {
        for duration in RetrySequence(strategy: strategy ?? self.strategy) {
            try Task.checkCancellation()

            do {
                return try await closure()
            } catch {
                await onFailure?(error)
            }

            try await Task.sleep(nanoseconds: duration)
        }

        throw RetryPolicyError.retryLimitExceeded
    }
}
