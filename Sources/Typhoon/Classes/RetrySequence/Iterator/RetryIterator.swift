//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Foundation

// MARK: - RetryIterator

struct RetryIterator: IteratorProtocol {
    // MARK: Properties

    private var retries: UInt = 0

    private let strategy: RetryPolicyStrategy

    // MARK: Initialization

    init(strategy: RetryPolicyStrategy) {
        self.strategy = strategy
    }

    // MARK: IteratorProtocol

    mutating func next() -> UInt64? {
        guard isValid() else { return nil }

        defer { retries += 1 }

        return delay()
    }

    // MARK: Private

    private func isValid() -> Bool {
        retries < strategy.retries
    }

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

    private func convertToNanoseconds(_ duration: DispatchTimeInterval) -> UInt64? {
        guard let seconds = duration.double else { return .zero }
        return safeConvertToUInt64(seconds * .nanosec)
    }

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

    private func calculateMaxDelay(_ maxInterval: DispatchTimeInterval?) -> Double {
        guard let maxSeconds = maxInterval?.double else {
            return Double(UInt64.max)
        }

        let maxNanos = maxSeconds * .nanosec
        return min(maxNanos, Double(UInt64.max))
    }

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
