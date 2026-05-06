//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

import Foundation

/// Represents the action to take after a failed attempt.
public enum RetryAction: Sendable, ExpressibleByBooleanLiteral {
    /// Retry the operation according to the strategy (with delay).
    case retry
    /// Retry the operation immediately, skipping the strategy's delay.
    case skipDelay
    /// Stop retrying and rethrow the last error.
    case stop

    // MARK: Initialization

    public init(booleanLiteral value: Bool) {
        self = value ? .retry : .stop
    }
}
