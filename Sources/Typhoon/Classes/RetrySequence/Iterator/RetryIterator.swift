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
            if let duration = duration.double {
                return UInt64(duration * .nanosec)
            }
        case let .exponential(_, multiplier, duration):
            if let duration = duration.double {
                let value = duration * pow(multiplier, Double(retries))
                return UInt64(value * .nanosec)
            }
        case let .exponentialWithJitter(_, jitterFactor, maxInterval, multiplier, duration):
            if let duration = duration.double {
                let exponentialBackoff = duration * pow(multiplier, Double(retries))
                let jitter = Double.random(in: -jitterFactor * exponentialBackoff ... jitterFactor * exponentialBackoff)
                let value = max(0, exponentialBackoff + jitter)
                return min(maxInterval ?? UInt64.max, UInt64(value * .nanosec))
            }
        }

        return 0
    }
}

// MARK: - Constants

private extension Double {
    static let nanosec: Double = 1e+9
}
