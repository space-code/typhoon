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
        let sequence = RetrySequence(strategy: .constant(retry: .retry, duration: .nanosecond))

        // when
        let result: [UInt64] = sequence.map { $0 }

        // then
        XCTAssertEqual(result, [1, 1, 1, 1, 1, 1, 1, 1])
    }

    func test_thatRetrySequenceCreatesASequence_whenStrategyIsExponential() {
        // given
        let sequence = RetrySequence(strategy: .exponential(retry: .retry, duration: .nanosecond))

        // when
        let result: [UInt64] = sequence.map { $0 }

        // then
        XCTAssertEqual(result, [1, 2, 4, 8, 16, 32, 64, 128])
    }

    func test_thatRetrySequenceCreatesASequence_whenStrategyIsExponentialWithJitter() {
        // given
        let sequence = RetrySequence(
            strategy: .exponentialWithJitter(
                retry: .retry,
                jitterFactor: .jitterFactor,
                maxInterval: .maxInterval,
                duration: .nanosecond
            )
        )

        // when
        let result: [UInt64] = sequence.map { $0 }

        // then
        XCTAssertEqual(result.count, 8)
        XCTAssertEqual(result[0], 1, accuracy: 1)
        XCTAssertEqual(result[1], 2, accuracy: 1)
        XCTAssertEqual(result[2], 4, accuracy: 1)
        XCTAssertEqual(result[3], 8, accuracy: 1)
        XCTAssertEqual(result[4], 16, accuracy: 2)
        XCTAssertEqual(result[5], 32, accuracy: 4)
        XCTAssertEqual(result[6], 64, accuracy: 7)
        XCTAssertEqual(result[7], .maxInterval)
    }

    func test_thatRetrySequenceDoesNotLimitASequence_whenStrategyIsExponentialWithJitterAndMaxIntervalIsNil() {
        // given
        let sequence = RetrySequence(
            strategy: .exponentialWithJitter(
                retry: .retry,
                jitterFactor: .jitterFactor,
                maxInterval: nil,
                duration: .nanosecond
            )
        )

        // when
        let result: [UInt64] = sequence.map { $0 }

        // then
        XCTAssertEqual(result.count, 8)
        XCTAssertEqual(result[0], 1, accuracy: 1)
        XCTAssertEqual(result[1], 2, accuracy: 1)
        XCTAssertEqual(result[2], 4, accuracy: 1)
        XCTAssertEqual(result[3], 8, accuracy: 1)
        XCTAssertEqual(result[4], 16, accuracy: 2)
        XCTAssertEqual(result[5], 32, accuracy: 4)
        XCTAssertEqual(result[6], 64, accuracy: 8)
        XCTAssertEqual(result[7], 128, accuracy: 13)
    }
}

// MARK: - Constant

private extension Int {
    static let retry: Int = 8
}

private extension UInt64 {
    static let maxInterval: UInt64 = 60
}

private extension Double {
    static let multiplier = 2.0
    static let jitterFactor = 0.1
}

private extension DispatchTimeInterval {
    static let nanosecond = DispatchTimeInterval.nanoseconds(1)
}
