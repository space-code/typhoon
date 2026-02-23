//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

/// A strategy that defines how delays between retry attempts are calculated.
///
/// Implementations can provide different backoff algorithms,
/// such as constant, linear, exponential, or exponential with jitter.
public protocol IRetryDelayStrategy: Sendable {
    /// Calculates the delay before the next retry attempt.
    ///
    /// - Parameter retries: The current retry attempt index,
    ///   starting from `0`.
    /// - Returns: The delay in nanoseconds, or `nil` if
    ///   no further retries should be performed.
    func delay(forRetry retries: UInt) -> UInt64?
}
