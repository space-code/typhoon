//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

import Foundation

/// A retry delay strategy that increases the delay
/// following the Fibonacci sequence.
///
/// The delay is calculated as:
/// `baseDuration * fibonacci(retryIndex + 1)`
struct FibonacciDelayStrategy: IRetryDelayStrategy {
    // MARK: - Properties

    /// The base delay interval.
    ///
    /// Each retry multiplies this value by
    /// the corresponding Fibonacci number.
    let duration: DispatchTimeInterval

    // MARK: - IRetryDelayStrategy

    /// Calculates a delay based on the Fibonacci sequence.
    ///
    /// - Parameter retries: The current retry attempt index (starting from `0`).
    /// - Returns: The delay in nanoseconds.
    func delay(forRetry retries: UInt) -> UInt64? {
        guard let nanos = duration.nanoseconds else { return .zero }
        return nanos * fibonacci(retries + 1)
    }

    // MARK: - Private

    /// Returns the Fibonacci number for a given index.
    ///
    /// Uses an iterative approach to avoid recursion overhead.
    private func fibonacci(_ n: UInt) -> UInt64 {
        guard n > 1 else { return 1 }

        var previous: UInt = 1
        var current: UInt = 1

        for _ in 2 ..< n {
            let next = previous + current
            previous = current
            current = next
        }

        return UInt64(current)
    }
}
