//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Foundation

// MARK: - RetryPolicyStrategy

/// A strategy used to define different retry policies.
public enum RetryPolicyStrategy: Sendable {
    /// A retry strategy with a constant number of attempts and fixed duration between retries.
    ///
    /// - Parameters:
    ///   - retry: The number of retry attempts.
    ///   - duration: The initial duration between retries.
    case constant(retry: UInt, duration: DispatchTimeInterval)

    /// A retry strategy with a linearly increasing delay.
    ///
    /// The delay grows proportionally with each retry attempt:
    /// `duration * (retryIndex + 1)`.
    ///
    /// - Parameters:
    ///   - retry: The maximum number of retry attempts.
    ///   - duration: The base delay used to calculate
    ///               the linear backoff interval.
    case linear(retry: UInt, duration: DispatchTimeInterval)

    /// A retry strategy with exponential increase in duration between retries and added jitter.
    ///
    /// - Parameters:
    ///   - retry: The number of retry attempts.
    ///   - jitterFactor: The factor to control the amount of jitter (default is 0.1).
    ///   - maxInterval: The maximum allowed interval between retries (default is 60 seconds).
    ///   - multiplier: The multiplier for calculating the exponential backoff duration (default is 2).
    ///   - duration: The initial duration between retries.
    case exponential(
        retry: UInt,
        jitterFactor: Double = 0.1,
        maxInterval: DispatchTimeInterval? = .seconds(60),
        multiplier: Double = 2,
        duration: DispatchTimeInterval
    )

    /// The number of retry attempts based on the strategy.
    public var retries: UInt {
        switch self {
        case let .constant(retry, _):
            retry
        case let .exponential(retry, _, _, _, _):
            retry
        case let .linear(retry, _):
            retry
        }
    }

    /// The time duration between retries based on the strategy.
    public var duration: DispatchTimeInterval {
        switch self {
        case let .constant(_, duration):
            duration
        case let .exponential(_, _, _, _, duration):
            duration
        case let .linear(_, duration):
            duration
        }
    }
}

extension RetryPolicyStrategy {
    var strategy: IRetryDelayStrategy {
        switch self {
        case let .exponential(_, jitterFactor, maxInterval, multiplier, duration):
            ExponentialDelayStrategy(
                duration: duration,
                multiplier: multiplier,
                jitterFactor: jitterFactor,
                maxInterval: maxInterval
            )
        case let .constant(_, duration):
            ConstantDelayStrategy(duration: duration)
        case let .linear(_, duration):
            LinearDelayStrategy(duration: duration)
        }
    }
}
