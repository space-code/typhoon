//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

import Foundation

struct ExponentialDelayStrategy: IRetryDelayStrategy {
    // MARK: - Properties

    /// The initial delay duration before the first retry attempt.
    ///
    /// This value acts as the base interval for exponential backoff.
    let duration: DispatchTimeInterval

    /// The exponential growth multiplier.
    ///
    /// Each subsequent retry delay is calculated as:
    /// `baseDelay * pow(multiplier, retryIndex)`
    let multiplier: Double

    /// A value between `0.0` and `1.0` that defines
    /// the percentage of randomness applied to the delay.
    ///
    /// For example, `0.2` means the final delay may vary
    /// ±20% around the computed exponential value.
    let jitterFactor: Double

    /// An optional upper bound for the delay interval.
    ///
    /// If specified, the computed delay will never exceed this value.
    let maxInterval: DispatchTimeInterval?

    // MARK: - IRetryDelayStrategy

    /// Calculates the delay for a given retry attempt using
    /// exponential backoff with optional jitter.
    ///
    /// - Parameter retries: The current retry attempt index (starting at `0`).
    /// - Returns: The delay in nanoseconds, or `nil` if it cannot be computed.
    func delay(forRetry retries: UInt) -> UInt64? {
        guard let seconds = duration.double else { return .zero }

        let maxDelayNanos = maxInterval.flatMap(\.double)
            .map { min($0 * .nanosec, Double(UInt64.max)) } ?? Double(UInt64.max)

        let base = seconds * .nanosec * pow(multiplier, Double(retries))

        guard base < maxDelayNanos, base < Double(UInt64.max) else {
            return maxDelayNanos.safeUInt64
        }

        let jitterRange = base * jitterFactor
        let jittered = Double.random(
            in: max(0, base - jitterRange) ... min(base + jitterRange, maxDelayNanos)
        )

        return min(jittered, maxDelayNanos).safeUInt64
    }
}
