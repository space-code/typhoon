//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

import Foundation

/// A retry delay strategy that increases the delay linearly
/// with each retry attempt.
///
/// The delay is calculated as:
/// `baseDuration * (retryIndex + 1)`
struct LinearDelayStrategy: IRetryDelayStrategy {
    // MARK: Properties

    /// The base delay interval.
    let duration: DispatchTimeInterval

    // MARK: IRetryDelayStrategy

    /// Calculates a linearly increasing delay.
    ///
    /// - Parameter retries: The current retry attempt index (starting from `0`).
    /// - Returns: The delay in nanoseconds.
    ///
    /// The formula used:
    /// `baseDuration * (retries + 1)`
    func delay(forRetry retries: UInt) -> UInt64? {
        guard let nanos = duration.nanoseconds else { return .zero }
        return nanos * UInt64(retries + 1)
    }
}
