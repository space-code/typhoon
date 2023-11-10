//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

@testable import Typhoon
import XCTest

// MARK: - RetrySequenceTests

final class RetrySequenceTests: XCTestCase {
    // MARK: Tests

    func test_thatRetrySequenceCreatesASequence_whenStrategyIsConstant() {
        // given
        let sequence = RetrySequence(strategy: .constant(retry: .retry, duration: .nanoseconds(1)))

        // when
        let result: [UInt64] = sequence.map { $0 }

        // then
        XCTAssertEqual(result, [1, 1, 1, 1, 1, 1])
    }

    func test_thatRetrySequenceCreatesASequence_whenStrategyIsExponential() {
        // given
        let sequence = RetrySequence(strategy: .exponential(retry: .retry, multiplier: 2, duration: .nanoseconds(1)))

        // when
        let result: [UInt64] = sequence.map { $0 }

        // then
        XCTAssertEqual(result, [1, 2, 4, 8, 16, 32])
    }
}

// MARK: - Constant

private extension Int {
    static let retry: Int = 6
}
