//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

import Foundation

/// Represents the result of executing a closure with a retry policy.
public struct RetryResult<T> {
    /// The successfully returned value from the closure.
    public let value: T

    /// The number of retry attempts performed.
    public let attempts: UInt

    /// Total duration spent on all retry attempts, in seconds.
    public let totalDuration: TimeInterval

    /// List of errors encountered during each failed attempt.
    public let errors: [Error]
}
