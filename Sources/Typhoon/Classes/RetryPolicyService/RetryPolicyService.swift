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

    /// An optional logger used to record retry attempts and related events.
    private let logger: ILogger?

    // MARK: Initialization

    /// Initializes a new instance of `RetryPolicyService`.
    ///
    /// - Parameters:
    ///   - strategy: The strategy that determines how retries are performed.
    ///   - maxTotalDuration: Optional maximum duration for all retries combined. If `nil`,
    ///                       retries can continue indefinitely based on the strategy.
    ///   -  logger: An optional logger for capturing retry-related information.
    public init(
        strategy: RetryPolicyStrategy,
        maxTotalDuration: DispatchTimeInterval? = nil,
        logger: ILogger? = nil
    ) {
        self.strategy = strategy
        self.maxTotalDuration = maxTotalDuration
        self.logger = logger
    }

    // MARK: Private

    private func calculateDeadline() -> Date? {
        maxTotalDuration?.nanoseconds.map {
            Date().addingTimeInterval(TimeInterval($0) / 1_000_000_000)
        }
    }

    private func checkDeadline(_ deadline: Date?, attempt: Int) throws {
        if let deadline, Date() > deadline {
            logger?.error("[RetryPolicy] Total duration exceeded after \(attempt) attempt(s).")
            throw RetryPolicyError.totalDurationExceeded
        }
    }

    private func handleRetryDecision(
        error: Error,
        onFailure: (@Sendable (Error) async -> Bool)?,
        iterator: inout some IteratorProtocol<UInt64>,
        attempt: Int
    ) async throws {
        if let onFailure, await !onFailure(error) {
            logger?.warning("[RetryPolicy] Stopped retrying after \(attempt) attempt(s) — onFailure returned false.")
            throw error
        }

        guard let duration = iterator.next() else {
            logger?.error("[RetryPolicy] Retry limit exceeded after \(attempt) attempt(s).")
            throw RetryPolicyError.retryLimitExceeded
        }

        logger?.info("[RetryPolicy] Waiting \(duration)ns before attempt \(attempt + 1)...")
        try Task.checkCancellation()
        try await Task.sleep(nanoseconds: duration)
    }

    private func logSuccess(attempt: Int) {
        if attempt > 0 {
            logger?.info("[RetryPolicy] Succeeded after \(attempt + 1) attempt(s).")
        }
    }

    private func logFailure(attempt: Int, error: Error) {
        logger?.warning("[RetryPolicy] Attempt \(attempt) failed: \(error.localizedDescription).")
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
        let deadline = calculateDeadline()
        var attempt = 0

        while true {
            try checkDeadline(deadline, attempt: attempt)

            do {
                let result = try await closure()
                logSuccess(attempt: attempt)
                return result
            } catch {
                attempt += 1
                logFailure(attempt: attempt, error: error)

                try await handleRetryDecision(
                    error: error,
                    onFailure: onFailure,
                    iterator: &iterator,
                    attempt: attempt
                )
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
