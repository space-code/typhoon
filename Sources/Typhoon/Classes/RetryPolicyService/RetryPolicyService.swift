//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Foundation

// MARK: - RetryPolicyService

/// `RetryPolicyService` provides a high-level API for retrying asynchronous
/// operations using configurable retry strategies.
///
/// The service encapsulates retry logic such as:
/// - limiting the number of retry attempts,
/// - applying delays between retries (e.g. fixed, exponential, or custom),
/// - reacting to errors on each failed attempt.
///
/// This class is typically used for retrying unstable operations like
/// network requests, database calls, or interactions with external services.
///
/// ### Example
/// ```swift
/// let strategy = RetryPolicyStrategy.exponential(
///     maxAttempts: 3,
///     initialDelay: .milliseconds(500)
/// )
///
/// let retryService = RetryPolicyService(strategy: strategy)
///
/// let data = try await retryService.retry(
///     strategy: nil,
///     onFailure: { error in
///         print("Request failed with error: \(error)")
///
///         // Return `true` to continue retrying,
///         // or `false` to stop and rethrow the error.
///         return true
///     }
/// ) {
///     try await apiClient.fetchData()
/// }
/// ```
///
///
/// In this example:
/// - The request will be retried up to 3 times.
/// - The delay between retries grows exponentially.
/// - Each failure is logged before the next attempt.
/// - If all retries are exhausted, `RetryPolicyError.retryLimitExceeded` is thrown.
///
/// - Note: You can override the default strategy per call by passing a custom
///   `RetryPolicyStrategy` into the `retry` method.
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
        let effectiveStrategy = strategy ?? self.strategy

        var iterator = RetrySequence(strategy: effectiveStrategy).makeIterator()

        while true {
            do {
                return try await closure()
            } catch {
                let shouldContinue = await onFailure?(error) ?? true

                if !shouldContinue {
                    throw error
                }

                guard let duration = iterator.next() else {
                    throw RetryPolicyError.retryLimitExceeded
                }

                try Task.checkCancellation()

                try await Task.sleep(nanoseconds: duration)
            }
        }
    }
}
