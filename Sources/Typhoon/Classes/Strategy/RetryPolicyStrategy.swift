//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Foundation

/// A strategy used to define different retry policies.
public enum RetryPolicyStrategy: Sendable {
    /// A retry strategy with a constant number of attempts and fixed duration between retries.
    ///
    /// - Parameters:
    ///   - retry: The number of retry attempts.
    ///   - duration: The initial duration between retries.
    case constant(retry: Int, duration: DispatchTimeInterval)

    /// A retry strategy with an exponential increase in duration between retries.
    ///
    /// - Parameters:
    ///   - retry: The number of retry attempts.
    ///   - multiplier: The multiplier for calculating the exponential backoff duration (default is 2).
    ///   - duration: The initial duration between retries.
    case exponential(retry: Int, multiplier: Double = 2, duration: DispatchTimeInterval)

    /// A retry strategy with exponential increase in duration between retries and added jitter.
    ///
    /// - Parameters:
    ///   - retry: The number of retry attempts.
    ///   - jitterFactor: The factor to control the amount of jitter (default is 0.1).
    ///   - maxInterval: The maximum allowed interval between retries (default is 60 seconds).
    ///   - multiplier: The multiplier for calculating the exponential backoff duration (default is 2).
    ///   - duration: The initial duration between retries.
    case exponentialWithJitter(
        retry: Int,
        jitterFactor: Double = 0.1,
        maxInterval: UInt64? = 60,
        multiplier: Double = 2,
        duration: DispatchTimeInterval
    )

    /// The number of retry attempts based on the strategy.
    public var retries: Int {
        switch self {
        case let .constant(retry, _):
            retry
        case let .exponential(retry, _, _):
            retry
        case let .exponentialWithJitter(retry, _, _, _, _):
            retry
        }
    }

    /// The time duration between retries based on the strategy.
    public var duration: DispatchTimeInterval {
        switch self {
        case let .constant(_, duration):
            duration
        case let .exponential(_, _, duration):
            duration
        case let .exponentialWithJitter(_, _, _, _, duration):
            duration
        }
    }
}
