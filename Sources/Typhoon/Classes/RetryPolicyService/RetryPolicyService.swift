//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
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
    /// Retries a closure with a given strategy.
    ///
    /// - Parameters:
    ///   - strategy: The strategy defining the behavior of the retry policy.
    ///   - onFailure: An optional closure called on each failure to handle or log errors.
    ///   - closure: The closure that will be retried based on the specified strategy.
    ///
    /// - Returns: The result of the closure's execution after retrying based on the policy.
    public func retry<T>(
        strategy: RetryPolicyStrategy?,
        onFailure: (@Sendable (Error) async -> Bool)?,
        _ closure: @Sendable () async throws -> T
    ) async throws -> T {
        for duration in RetrySequence(strategy: strategy ?? self.strategy) {
            try Task.checkCancellation()

            do {
                return try await closure()
            } catch {
                let shouldContinue = await onFailure?(error) ?? true

                if !shouldContinue {
                    throw error
                }
            }

            try await Task.sleep(nanoseconds: duration)
        }

        throw RetryPolicyError.retryLimitExceeded
    }
}
