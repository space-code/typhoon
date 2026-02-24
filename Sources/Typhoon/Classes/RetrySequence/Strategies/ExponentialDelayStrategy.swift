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

    // MARK: Initialization

    init(
        duration: DispatchTimeInterval,
        multiplier: Double = 2.0,
        jitterFactor: Double = 0.1,
        maxInterval: DispatchTimeInterval? = .seconds(60)
    ) {
        self.duration = duration
        self.multiplier = multiplier
        self.jitterFactor = jitterFactor
        self.maxInterval = maxInterval
    }

    // MARK: - IRetryDelayStrategy

    /// Calculates the delay for a given retry attempt using
    /// exponential backoff with optional jitter.
    ///
    /// - Parameter retries: The current retry attempt index (starting at `0`).
    /// - Returns: The delay in nanoseconds, or `nil` if it cannot be computed.
    func delay(forRetry retries: UInt) -> UInt64? {
        guard let baseNanos = duration.nanoseconds else { return .zero }

        let maxDelayNanos = maxInterval?.nanoseconds.map { UInt64($0) } ?? UInt64.max

        let base = Double(baseNanos) * pow(multiplier, Double(retries))

        guard base < Double(maxDelayNanos) else {
            return maxDelayNanos
        }

        let jitterRange = base * jitterFactor
        let jittered = Double.random(
            in: max(0, base - jitterRange) ... min(base + jitterRange, Double(maxDelayNanos))
        )

        return UInt64(jittered)
    }
}
