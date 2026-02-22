//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

import Foundation

struct ConstantDelayStrategy: IRetryDelayStrategy {
    // MARK: - Properties

    /// The fixed delay interval applied to every retry attempt.
    ///
    /// This value does not change based on the retry index.
    let duration: DispatchTimeInterval

    // MARK: - IRetryDelayStrategy

    /// Returns a constant delay for each retry attempt.
    ///
    /// - Parameter retries: The current retry attempt index (ignored).
    /// - Returns: The delay in nanoseconds.
    func delay(forRetry _: UInt) -> UInt64? {
        guard let seconds = duration.double else { return .zero }
        return (seconds * .nanosec).safeUInt64
    }
}
