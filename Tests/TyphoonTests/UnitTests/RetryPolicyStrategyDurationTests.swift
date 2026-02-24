//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

@testable import Typhoon
import XCTest

final class RetryPolicyStrategyDurationTests: XCTestCase {
    // MARK: Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else {
            throw XCTSkip("Duration is only available on iOS 16+")
        }
    }

    // MARK: - Constant

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    func test_thatConstantStrategy_convertsSecondsCorrectly() {
        // given
        let strategy = RetryPolicyStrategy.constant(retry: 3, duration: .seconds(2))

        // when
        let delay = strategy.strategy.delay(forRetry: 0)

        // then
        XCTAssertEqual(delay, 2 * 1_000_000_000)
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    func test_thatConstantStrategy_convertsMillisecondsCorrectly() {
        // given
        let strategy = RetryPolicyStrategy.constant(retry: 3, duration: .milliseconds(500))

        // when
        let delay = strategy.strategy.delay(forRetry: 0)

        // then
        XCTAssertEqual(delay, 500 * 1_000_000)
    }

    // MARK: - Linear

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    func test_thatLinearStrategy_convertsSecondsCorrectly() {
        // given
        let strategy = RetryPolicyStrategy.linear(retry: 3, duration: .seconds(1))

        // when
        let delays = (0 ..< 3).compactMap { strategy.strategy.delay(forRetry: UInt($0)) }

        // then
        XCTAssertEqual(delays, [
            UInt64(1) * 1_000_000_000,
            UInt64(2) * 1_000_000_000,
            UInt64(3) * 1_000_000_000,
        ])
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    func test_thatFibonacciStrategy_convertsSecondsCorrectly() {
        // given
        let strategy = RetryPolicyStrategy.fibonacci(retry: 5, duration: .seconds(1))

        // when
        let delays = (0 ..< 5).compactMap { strategy.strategy.delay(forRetry: UInt($0)) }

        // then
        XCTAssertEqual(delays, [
            UInt64(1) * 1_000_000_000,
            UInt64(1) * 1_000_000_000,
            UInt64(2) * 1_000_000_000,
            UInt64(3) * 1_000_000_000,
            UInt64(5) * 1_000_000_000,
        ])
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    func test_thatExponentialStrategy_convertsSecondsCorrectly() {
        // given
        let strategy = RetryPolicyStrategy.exponential(
            retry: 3,
            jitterFactor: 0.0,
            maxInterval: nil,
            multiplier: 2.0,
            duration: .seconds(1)
        )

        // when
        let delays = (0 ..< 3).compactMap { strategy.strategy.delay(forRetry: UInt($0)) }

        // then
        XCTAssertEqual(delays, [
            UInt64(1) * 1_000_000_000,
            UInt64(2) * 1_000_000_000,
            UInt64(4) * 1_000_000_000,
        ])
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    func test_thatExponentialStrategy_convertsMaxIntervalCorrectly() {
        // given
        let strategy = RetryPolicyStrategy.exponential(
            retry: 4,
            jitterFactor: 0.0,
            maxInterval: .seconds(3),
            multiplier: 2.0,
            duration: .seconds(1)
        )

        // when
        let delays = (0 ..< 4).compactMap { strategy.strategy.delay(forRetry: UInt($0)) }

        // then
        XCTAssertEqual(delays, [
            UInt64(1) * 1_000_000_000,
            UInt64(2) * 1_000_000_000,
            UInt64(3) * 1_000_000_000,
            UInt64(3) * 1_000_000_000,
        ])
    }
}
