//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

@testable import Typhoon
import XCTest

// MARK: - FibonacciDelayStrategyTests

final class FibonacciDelayStrategyTests: XCTestCase {
    // MARK: Properties

    private var sut: FibonacciDelayStrategy!

    // MARK: Lifecycle

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_thatDelayIsZero_whenDurationIsNever() {
        // given
        sut = FibonacciDelayStrategy(duration: .never)

        // when
        let result = sut.delay(forRetry: 0)

        // then
        XCTAssertEqual(result, .zero)
    }

    func test_thatDelayFollowsFibonacciSequence() {
        // given
        sut = FibonacciDelayStrategy(duration: .nanoseconds(1))

        // when
        let results = (0 ..< 8).compactMap { sut.delay(forRetry: UInt($0)) }

        // then
        XCTAssertEqual(results, [1, 1, 2, 3, 5, 8, 13, 21])
    }

    func test_thatDelayScalesWithBaseDuration() {
        // given
        sut = FibonacciDelayStrategy(duration: .nanoseconds(2))

        // when
        let results = (0 ..< 5).compactMap { sut.delay(forRetry: UInt($0)) }

        // then
        XCTAssertEqual(results, [2, 2, 4, 6, 10])
    }
}
