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

    /// Optional maximum total duration allowed for all retry attempts.
    private let maxTotalDuration: DispatchTimeInterval?

    // MARK: Initialization

    /// Initializes a new instance of `RetryPolicyService`.
    ///
    /// - Parameters:
    ///   - strategy: The strategy that determines how retries are performed.
    ///   - maxTotalDuration: Optional maximum duration for all retries combined. If `nil`,
    ///                       retries can continue indefinitely based on the
    /// strategy.
    public init(strategy: RetryPolicyStrategy, maxTotalDuration: DispatchTimeInterval? = nil) {
        self.strategy = strategy
        self.maxTotalDuration = maxTotalDuration
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

        let deadline = maxTotalDuration?.double.map { Date().addingTimeInterval($0) }

        while true {
            if let deadline, Date() > deadline {
                throw RetryPolicyError.totalDurationExceeded
            }

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

    /// Retries a closure and returns a detailed `RetryResult` including success/failure info.
    ///
    /// - Parameters:
    ///   - strategy: Optional strategy that defines the retry behavior.
    ///   - onFailure: Optional closure called on each failure; returning `true` stops retries.
    ///   - closure: The async closure to be retried according to the strategy.
    ///
    /// - Returns: A `RetryResult` containing the final value, attempt count, total duration, and encountered errors.
    public func retryWithResult<T>(
        strategy: RetryPolicyStrategy? = nil,
        onFailure: (@Sendable (Error) async -> Bool)? = nil,
        _ closure: @Sendable () async throws -> T
    ) async throws -> RetryResult<T> {
        let state = State()
        let startTime = Date()

        let value = try await retry(
            strategy: strategy,
            onFailure: { error in
                await state.recordError(error)
                return await onFailure?(error) ?? true
            }, {
                await state.recordAttempt()
                return try await closure()
            }
        )

        return await RetryResult(
            value: value,
            attempts: state.attempts,
            totalDuration: Date().timeIntervalSince(startTime),
            errors: state.errors
        )
    }
}

// MARK: RetryPolicyService.State

extension RetryPolicyService {
    /// Internal actor to track retry attempts and errors in a thread-safe manner.
    private actor State {
        /// Number of attempts performed so far.
        var attempts: UInt = 0

        /// List of errors encountered during retry attempts.
        var errors: [Error] = []

        /// Increments the attempt count by one.
        func recordAttempt() {
            attempts += 1
        }

        /// Records an error from a failed attempt.
        /// - Parameter error: The error to record.
        func recordError(_ error: Error) {
            errors.append(error)
        }
    }
}
