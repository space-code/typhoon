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
    ///   - dispatchDuration: The initial duration between retries.
    ///
    /// - Note: On iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, prefer using
    ///   ``constant(retry:duration:)`` with Swift's `Duration` type instead.
    case constant(retry: UInt, dispatchDuration: DispatchTimeInterval)

    /// A retry strategy with a linearly increasing delay.
    ///
    /// - Parameters:
    ///   - retry: The maximum number of retry attempts.
    ///   - dispatchDuration: The base delay used to calculate the linear backoff interval.
    ///
    /// - Note: On iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, prefer using
    ///   ``linear(retry:duration:)`` with Swift's `Duration` type instead.
    case linear(retry: UInt, dispatchDuration: DispatchTimeInterval)

    /// A retry strategy with a Fibonacci-based delay progression.
    ///
    /// - Parameters:
    ///   - retry: The maximum number of retry attempts.
    ///   - dispatchDuration: The base delay used to calculate the Fibonacci backoff interval.
    ///
    /// - Note: On iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, prefer using
    ///   ``fibonacci(retry:duration:)`` with Swift's `Duration` type instead.
    case fibonacci(retry: UInt, dispatchDuration: DispatchTimeInterval)

    /// A retry strategy with exponential increase in duration between retries and added jitter.
    ///
    /// - Parameters:
    ///   - retry: The number of retry attempts.
    ///   - jitterFactor: The factor to control the amount of jitter (default is 0.1).
    ///   - maxInterval: The maximum allowed interval between retries (default is 60 seconds).
    ///   - multiplier: The multiplier for calculating the exponential backoff duration (default is 2).
    ///   - dispatchDuration: The initial duration between retries.
    ///
    /// - Note: On iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, prefer using
    ///   ``exponential(retry:jitterFactor:maxInterval:multiplier:duration:)``
    ///   with Swift's `Duration` type instead.
    case exponential(
        retry: UInt,
        jitterFactor: Double = 0.1,
        maxInterval: DispatchTimeInterval? = .seconds(60),
        multiplier: Double = 2,
        dispatchDuration: DispatchTimeInterval
    )

    /// A custom retry strategy defined by a user-provided delay calculator.
    ///
    /// - Parameters:
    ///   - retry: The maximum number of retry attempts.
    ///   - strategy: A custom delay strategy implementation.
    case custom(retry: UInt, strategy: IRetryDelayStrategy)

    /// The number of retry attempts based on the strategy.
    public var retries: UInt {
        switch self {
        case let .constant(retry, _):
            retry
        case let .exponential(retry, _, _, _, _):
            retry
        case let .linear(retry, _):
            retry
        case let .fibonacci(retry, _):
            retry
        case let .custom(retry, _):
            retry
        }
    }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
public extension RetryPolicyStrategy {
    /// A retry strategy with a constant number of attempts and fixed duration between retries.
    ///
    /// - Parameters:
    ///   - retry: The number of retry attempts.
    ///   - duration: The initial duration between retries.
    static func constant(retry: UInt, duration: Duration) -> RetryPolicyStrategy {
        .constant(retry: retry, dispatchDuration: DispatchTimeInterval.from(duration))
    }

    /// A retry strategy with a linearly increasing delay.
    ///
    /// The delay grows proportionally with each retry attempt:
    /// `duration * (retryIndex + 1)`.
    ///
    /// - Parameters:
    ///   - retry: The maximum number of retry attempts.
    ///   - duration: The base delay used to calculate
    ///               the linear backoff interval.
    static func linear(retry: UInt, duration: Duration) -> RetryPolicyStrategy {
        .linear(retry: retry, dispatchDuration: DispatchTimeInterval.from(duration))
    }

    /// A retry strategy with a Fibonacci-based delay progression.
    ///
    /// The delay grows according to the Fibonacci sequence:
    /// `duration * fibonacci(retryIndex + 1)`.
    ///
    /// - Parameters:
    ///   - retry: The maximum number of retry attempts.
    ///   - duration: The base delay used to calculate
    ///               the Fibonacci backoff interval.
    static func fibonacci(retry: UInt, duration: Duration) -> RetryPolicyStrategy {
        .fibonacci(retry: retry, dispatchDuration: DispatchTimeInterval.from(duration))
    }

    /// A retry strategy with exponential increase in duration between retries and added jitter.
    ///
    /// - Parameters:
    ///   - retry: The number of retry attempts.
    ///   - jitterFactor: The factor to control the amount of jitter (default is 0.1).
    ///   - maxInterval: The maximum allowed interval between retries (default is 60 seconds).
    ///   - multiplier: The multiplier for calculating the exponential backoff duration (default is 2).
    ///   - duration: The initial duration between retries.
    static func exponential(
        retry: UInt,
        jitterFactor: Double = 0.1,
        maxInterval: Duration? = .seconds(60),
        multiplier: Double = 2.0,
        duration: Duration
    ) -> RetryPolicyStrategy {
        .exponential(
            retry: retry,
            jitterFactor: jitterFactor,
            maxInterval: maxInterval.map { DispatchTimeInterval.from($0) },
            multiplier: multiplier,
            dispatchDuration: DispatchTimeInterval.from(duration)
        )
    }
}

// MARK: Strategy

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
        case let .fibonacci(_, duration):
            FibonacciDelayStrategy(duration: duration)
        case let .custom(_, strategy):
            strategy
        }
    }
}

// MARK: - Chain

public extension RetryPolicyStrategy {
    /// Creates a `.custom` retry strategy using a chained delay strategy.
    ///
    /// The total number of retries is automatically calculated
    /// as the sum of all provided entries.
    ///
    /// - Parameter entries: Ordered delay strategy entries.
    /// - Returns: A `.custom` strategy wrapping `ChainDelayStrategy`.
    static func chain(_ entries: [ChainDelayStrategy.Entry]) -> RetryPolicyStrategy {
        let chain = ChainDelayStrategy(entries: entries)
        return .custom(retry: chain.totalRetries, strategy: chain)
    }
}
