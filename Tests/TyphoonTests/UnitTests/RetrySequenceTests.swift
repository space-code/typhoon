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

    func test_thatRetrySequenceCreatesASequence_whenStrategyIsLinear() {
        // given
        let sequence = RetrySequence(strategy: .linear(retry: .retry, duration: .nanosecond))

        // when
        let result: [UInt64] = sequence.map { $0 }

        // then
        XCTAssertEqual(result, [1, 2, 3, 4, 5, 6, 7, 8])
    }

    func test_thatRetrySequenceCreatesASequence_whenStrategyIsFibonacci() {
        // given
        let sequence = RetrySequence(strategy: .fibonacci(retry: .retry, duration: .nanosecond))

        // when
        let result: [UInt64] = sequence.map { $0 }

        // then
        XCTAssertEqual(result, [1, 1, 2, 3, 5, 8, 13, 21])
    }

    func test_thatRetrySequenceCreatesASequence_whenStrategyIsCustom() {
        // given
        let sequence = RetrySequence(strategy: .custom(retry: .retry, strategy: FibonacciDelayStrategy(duration: .nanosecond)))

        // when
        let result: [UInt64] = sequence.map { $0 }

        // then
        XCTAssertEqual(result, [1, 1, 2, 3, 5, 8, 13, 21])
    }

    func test_thatRetrySequenceCreatesASequence_whenStrategyIsExponential() {
        // given
        let sequence = RetrySequence(strategy: .exponential(retry: .retry, jitterFactor: .zero, duration: .nanosecond))

        // when
        let result: [UInt64] = sequence.map { $0 }

        // then
        XCTAssertEqual(result, [1, 2, 4, 8, 16, 32, 64, 128])
    }

    func test_thatRetrySequenceCreatesASequence_whenStrategyIsExponentialWithJitter() {
        // given
        let durationSeconds = 1.0
        let multiplier = 2.0
        let jitterFactor = 0.1

        let sequence = RetrySequence(
            strategy: .exponential(
                retry: 5,
                jitterFactor: jitterFactor,
                maxInterval: nil,
                multiplier: multiplier,
                duration: .seconds(Int(durationSeconds))
            )
        )

        // when
        let result: [UInt64] = sequence.map { $0 }

        // then
        XCTAssertEqual(result.count, 5)

        for (i, valueNanos) in result.enumerated() {
            let seconds = toSeconds(valueNanos)

            let expectedBase = durationSeconds * pow(multiplier, Double(i))

            let lowerBound = expectedBase * (1.0 - jitterFactor)
            let upperBound = expectedBase * (1.0 + jitterFactor)

            XCTAssertTrue(
                seconds >= lowerBound && seconds <= upperBound,
                "Attempt \(i): \(seconds)s should be between \(lowerBound)s and \(upperBound)s"
            )
        }
    }

    func test_thatRetrySequenceRespectsMaxInterval_whenStrategyIsExponentialWithJitter() {
        // given
        let maxIntervalDuration: DispatchTimeInterval = .seconds(10)
        let maxIntervalNanos: UInt64 = 10 * 1_000_000_000

        let sequence = RetrySequence(
            strategy: .exponential(
                retry: 10,
                jitterFactor: 0.1,
                maxInterval: maxIntervalDuration,
                multiplier: 2.0,
                duration: .seconds(1)
            )
        )

        // when
        let result: [UInt64] = sequence.map { $0 }

        // then
        XCTAssertEqual(result.count, 10)

        for (i, val) in result.enumerated() {
            XCTAssertLessThanOrEqual(val, maxIntervalNanos, "Attempt \(i) exceeded maxInterval")

            let expectedBaseSeconds = 1.0 * pow(2.0, Double(i))

            if expectedBaseSeconds * (1.0 - 0.1) > 10.0 {
                XCTAssertEqual(val, maxIntervalNanos, "Attempt \(i) should be capped at maxInterval")
            }
        }
    }

    func test_thatRetrySequenceAppliesJitter_whenStrategyIsExponentialWithJitter() {
        // given
        let strategy = RetryPolicyStrategy.exponential(
            retry: 30,
            jitterFactor: 0.5,
            maxInterval: nil,
            multiplier: 2.0,
            duration: .milliseconds(10)
        )

        let sequence1 = RetrySequence(strategy: strategy)
        let sequence2 = RetrySequence(strategy: strategy)

        // when
        let result1 = sequence1.map { $0 }
        let result2 = sequence2.map { $0 }

        // then
        XCTAssertEqual(result1.count, 30)

        XCTAssertNotEqual(result1, result2, "Two sequences with jitter should produce different values")

        for (i, val) in result1.enumerated() {
            let seconds = toSeconds(val)

            let base = 0.01 * pow(2.0, Double(i))

            let lower = base * 0.5
            let upper = base * 1.5

            XCTAssertTrue(
                seconds >= lower && seconds <= upper,
                "Attempt \(i): Value \(seconds) is out of bounds [\(lower), \(upper)]"
            )
        }
    }

    func test_thatRetrySequenceWorksWithoutMaxInterval_whenStrategyIsExponentialWithJitter() {
        // given
        let sequence = RetrySequence(
            strategy: .exponential(
                retry: 5,
                jitterFactor: 0.1,
                maxInterval: nil,
                multiplier: 2.0,
                duration: .seconds(1)
            )
        )

        // when
        let result: [UInt64] = sequence.map { $0 }

        // then
        XCTAssertEqual(result.count, 5)

        for i in 1 ..< result.count {
            XCTAssertGreaterThan(
                result[i],
                result[i - 1],
                "Each delay should be greater than previous (exponential growth)"
            )
        }

        XCTAssertGreaterThan(result[4], result[0] * 10)
    }

    func test_thatRetrySequenceDoesNotLimitASequence_whenStrategyIsExponentialWithJitterAndMaxIntervalIsNil() {
        // given
        let sequence = RetrySequence(
            strategy: .exponential(
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

    // MARK: Helpers

    private func toSeconds(_ nanos: UInt64) -> Double {
        Double(nanos) / 1_000_000_000
    }
}

// MARK: - Constant

private extension UInt {
    static let retry: UInt = 8
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
