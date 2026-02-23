//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

/// A delay strategy that chains multiple strategies sequentially.
///
/// Exhausts each strategy in order before moving to the next.
///
/// ### Example
/// ```swift
/// let strategy = ChainDelayStrategy(strategies: [
///     (retries: 3, strategy: ConstantDelayStrategy(duration: .milliseconds(100))),
///     (retries: 2, strategy: ExponentialDelayStrategy(duration: .seconds(1), ...))
/// ])
/// ```
public struct ChainDelayStrategy: IRetryDelayStrategy {
    // MARK: - Types

    /// Represents a single retry configuration entry.
    public struct Entry: Sendable {
        /// The maximum number of retry attempts.
        public let retries: UInt

        /// The delay strategy that determines how long to wait
        /// between retry attempts.
        public let strategy: IRetryDelayStrategy

        /// Creates a new retry configuration entry.
        ///
        /// - Parameters:
        ///   - retries: The maximum number of retry attempts.
        ///   - strategy: The delay strategy applied between attempts.
        public init(retries: UInt, strategy: IRetryDelayStrategy) {
            self.retries = retries
            self.strategy = strategy
        }
    }

    // MARK: - Properties

    /// Ordered retry configuration entries.
    private let entries: [Entry]

    /// The total number of retries supported by this chain.
    public let totalRetries: UInt

    // MARK: - Initialization

    /// Creates a chained delay strategy.
    ///
    /// - Parameter entries: Ordered retry configuration entries.
    ///   Strategies are evaluated in the order provided.
    public init(entries: [Entry]) {
        self.entries = entries
        totalRetries = entries.reduce(0) { $0 + $1.retries }
    }

    // MARK: - IRetryDelayStrategy

    /// Returns the delay for a given retry index.
    public func delay(forRetry retries: UInt) -> UInt64? {
        var offset: UInt = 0

        for entry in entries {
            if retries < offset + entry.retries {
                let localRetry = retries - offset
                return entry.strategy.delay(forRetry: localRetry)
            }
            offset += entry.retries
        }

        return nil
    }
}
