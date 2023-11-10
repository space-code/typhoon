//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Foundation

/// A strategy used to define different retry policies.
public enum RetryPolicyStrategy {
    /// A retry strategy with a constant number of attempts and fixed duration between retries.
    case constant(retry: Int, duration: DispatchTimeInterval)

    /// A retry strategy with an exponential increase in duration between retries.
    case exponential(retry: Int, multiplier: Double, duration: DispatchTimeInterval)

    /// The number of retry attempts based on the strategy.
    public var retries: Int {
        switch self {
        case let .constant(retry, _):
            return retry
        case let .exponential(retry, _, _):
            return retry
        }
    }

    /// The time duration between retries based on the strategy.
    public var duration: DispatchTimeInterval {
        switch self {
        case let .constant(_, duration):
            return duration
        case let .exponential(_, _, duration):
            return duration
        }
    }
}
