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

    /// The retry policy strategy that defines:
    /// - The maximum number of retry attempts.
    /// - The algorithm used to calculate delays between retries
    ///   (constant, exponential, or exponential with jitter).
    private let strategy: RetryPolicyStrategy

    // MARK: Initialization

    /// Creates a new `RetryIterator` with the specified retry policy strategy.
    ///
    /// - Parameter strategy: A `RetryPolicyStrategy` describing how retry delays
    ///   should be calculated and how many retries are allowed.
    init(strategy: RetryPolicyStrategy) {
        self.strategy = strategy
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
        guard isValid() else { return nil }

        defer { retries += 1 }

        return delay()
    }

    // MARK: Private

    /// Determines whether another retry attempt is allowed.
    ///
    /// This method compares the current retry count with the maximum
    /// number of retries defined in the retry strategy.
    ///
    /// - Returns: `true` if another retry attempt is allowed;
    ///   `false` otherwise.
    private func isValid() -> Bool {
        retries < strategy.retries
    }

    /// Calculates the delay for the current retry attempt
    /// based on the selected retry strategy.
    ///
    /// - Returns: The computed delay in nanoseconds, or `0`
    ///   if the duration cannot be converted to seconds.
    private func delay() -> UInt64? {
        switch strategy {
        case let .constant(_, duration):
            convertToNanoseconds(duration)

        case let .exponential(_, multiplier, duration):
            calculateExponentialDelay(
                duration: duration,
                multiplier: multiplier,
                retries: retries
            )

        case let .exponentialWithJitter(_, jitterFactor, maxInterval, multiplier, duration):
            calculateExponentialDelayWithJitter(
                duration: duration,
                multiplier: multiplier,
                retries: retries,
                jitterFactor: jitterFactor,
                maxInterval: maxInterval
            )
        }
    }

    // MARK: - Helper Methods

    /// Converts a `DispatchTimeInterval` to nanoseconds.
    ///
    /// - Parameter duration: The time interval to convert.
    /// - Returns: The equivalent duration in nanoseconds, or `0`
    ///   if the interval cannot be represented as seconds.
    private func convertToNanoseconds(_ duration: DispatchTimeInterval) -> UInt64? {
        guard let seconds = duration.double else { return .zero }
        return safeConvertToUInt64(seconds * .nanosec)
    }

    /// Calculates an exponential backoff delay without jitter.
    ///
    /// The delay is calculated as:
    /// `baseDelay * multiplier ^ retries`
    ///
    /// - Parameters:
    ///   - duration: The base delay value.
    ///   - multiplier: The exponential growth multiplier.
    ///   - retries: The current retry attempt index.
    /// - Returns: The calculated delay in nanoseconds.
    private func calculateExponentialDelay(
        duration: DispatchTimeInterval,
        multiplier: Double,
        retries: UInt
    ) -> UInt64? {
        guard let seconds = duration.double else { return .zero }

        let baseNanos = seconds * .nanosec
        let value = baseNanos * pow(multiplier, Double(retries))

        return safeConvertToUInt64(value)
    }

    /// Calculates an exponential backoff delay with jitter and an optional maximum interval.
    ///
    /// This method:
    /// 1. Calculates the exponential backoff delay.
    /// 2. Applies a random jitter to spread retry attempts over time.
    /// 3. Caps the result at the provided maximum interval, if any.
    ///
    /// - Parameters:
    ///   - duration: The base delay value.
    ///   - multiplier: The exponential growth multiplier.
    ///   - retries: The current retry attempt index.
    ///   - jitterFactor: The percentage of randomness applied to the delay.
    ///   - maxInterval: An optional upper bound for the delay.
    /// - Returns: The final delay in nanoseconds.
    private func calculateExponentialDelayWithJitter(
        duration: DispatchTimeInterval,
        multiplier: Double,
        retries: UInt,
        jitterFactor: Double,
        maxInterval: DispatchTimeInterval?
    ) -> UInt64? {
        guard let seconds = duration.double else { return .zero }

        let maxDelayNanos = calculateMaxDelay(maxInterval)
        let baseNanos = seconds * .nanosec
        let exponentialBackoffNanos = baseNanos * pow(multiplier, Double(retries))

        guard exponentialBackoffNanos < maxDelayNanos,
              exponentialBackoffNanos < Double(UInt64.max)
        else {
            return safeConvertToUInt64(maxDelayNanos)
        }

        let delayWithJitter = applyJitter(
            to: exponentialBackoffNanos,
            factor: jitterFactor,
            maxDelay: maxDelayNanos
        )

        return safeConvertToUInt64(min(delayWithJitter, maxDelayNanos))
    }

    /// Calculates the maximum allowed delay in nanoseconds.
    ///
    /// - Parameter maxInterval: An optional maximum delay value.
    /// - Returns: The maximum delay in nanoseconds, clamped to `UInt64.max`.
    private func calculateMaxDelay(_ maxInterval: DispatchTimeInterval?) -> Double {
        guard let maxSeconds = maxInterval?.double else {
            return Double(UInt64.max)
        }

        let maxNanos = maxSeconds * .nanosec
        return min(maxNanos, Double(UInt64.max))
    }

    /// Applies random jitter to a delay value.
    ///
    /// Jitter helps prevent synchronized retries (the "thundering herd" problem)
    /// by randomizing retry timings within a defined range.
    ///
    /// - Parameters:
    ///   - value: The base delay value in nanoseconds.
    ///   - factor: The jitter factor defining the randomization range.
    ///   - maxDelay: The maximum allowed delay.
    /// - Returns: A jittered delay value clamped to valid bounds.
    private func applyJitter(
        to value: Double,
        factor: Double,
        maxDelay: Double
    ) -> Double {
        let jitterRange = value * factor
        let minValue = value - jitterRange
        let maxValue = min(value + jitterRange, maxDelay)

        guard maxValue < Double(UInt64.max) else {
            return maxDelay
        }

        let randomized = Double.random(in: minValue ... maxValue)
        return max(0, randomized)
    }

    private func safeConvertToUInt64(_ value: Double) -> UInt64 {
        if value >= Double(UInt64.max) {
            return UInt64.max
        }
        if value <= 0 {
            return .zero
        }
        return UInt64(value)
    }
}

// MARK: - Constants

private extension Double {
    static let nanosec: Double = 1e+9
}
