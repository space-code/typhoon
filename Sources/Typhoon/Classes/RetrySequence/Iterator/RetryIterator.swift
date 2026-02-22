//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Foundation

// MARK: - RetryIterator

/// An iterator that generates retry delays according to a retry policy strategy.
///
/// `RetryIterator` conforms to `IteratorProtocol` and produces a sequence of delay
/// values (in nanoseconds) that can be used to schedule retry attempts for
/// asynchronous operations such as network requests or background tasks.
///
/// Each call to `next()` returns the delay for the current retry attempt and then
/// advances the internal retry counter. When the maximum number of retries defined
/// by the strategy is reached, the iterator stops producing values.
struct RetryIterator: IteratorProtocol {
    // MARK: Properties

    /// The current retry attempt index.
    ///
    /// Starts from `0` and is incremented after each successful call to `next()`.
    /// This value is used when calculating exponential backoff delays.
    private var retries: UInt = 0

    /// The maximum number of retry attempts allowed.
    ///
    /// Once the number of attempts reaches this value,
    /// the iterator stops producing further delays.
    private let maxRetries: UInt

    /// The retry policy strategy that defines:
    /// - The maximum number of retry attempts.
    /// - The algorithm used to calculate delays between retries
    ///   (constant, exponential, or exponential with jitter).
    private let delayStrategy: any IRetryDelayStrategy

    // MARK: Initialization

    /// Creates a new `RetryIterator`.
    ///
    /// - Parameters:
    ///   - maxRetries: The maximum number of retry attempts allowed.
    ///   - delayStrategy: A strategy that defines how delays between
    ///     retry attempts are calculated.
    init(maxRetries: UInt, delayStrategy: any IRetryDelayStrategy) {
        self.maxRetries = maxRetries
        self.delayStrategy = delayStrategy
    }

    // MARK: IteratorProtocol

    /// Returns the delay for the next retry attempt.
    ///
    /// The delay is calculated according to the current retry policy strategy
    /// and expressed in **nanoseconds**, making it suitable for use with
    /// `DispatchQueue`, `Task.sleep`, or other low-level scheduling APIs.
    ///
    /// After the delay is calculated, the internal retry counter is incremented.
    /// When the maximum number of retries is exceeded, this method returns `nil`,
    /// signaling the end of the iteration.
    ///
    /// - Returns: The delay in nanoseconds for the current retry attempt,
    ///   or `nil` if no more retries are allowed.
    mutating func next() -> UInt64? {
        guard retries < maxRetries else { return nil }
        defer { retries += 1 }
        return delayStrategy.delay(forRetry: retries)
    }
}
