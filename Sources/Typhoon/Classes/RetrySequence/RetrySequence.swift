//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Foundation

/// An object that represents a sequence for retry policies.
struct RetrySequence: Sequence {
    // MARK: Properties

    /// The strategy defining the behavior of the retry policy.
    private let strategy: RetryPolicyStrategy

    // MARK: Initialization

    /// Creates a new `RetrySequence` instance.
    ///
    /// - Parameter strategy: The strategy defining the behavior of the retry policy.
    init(strategy: RetryPolicyStrategy) {
        self.strategy = strategy
    }

    // MARK: Sequence

    func makeIterator() -> RetryIterator {
        RetryIterator(strategy: strategy)
    }
}
