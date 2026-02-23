//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

@testable import Typhoon
import XCTest

// MARK: - ExponentialDelayStrategyTests

final class ExponentialDelayStrategyTests: XCTestCase {
    // MARK: Properties

    private var sut: ExponentialDelayStrategy!

    // MARK: Lifecycle

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_thatDelayIsZero_whenDurationIsNever() {
        // given
        sut = ExponentialDelayStrategy(duration: .never, jitterFactor: 0.0)

        // when
        let result = sut.delay(forRetry: 0)

        // then
        XCTAssertEqual(result, .zero)
    }

    func test_thatDelayGrowsExponentially_whenJitterIsDisabled() {
        // given
        sut = ExponentialDelayStrategy(
            duration: .nanoseconds(1),
            multiplier: 2.0,
            jitterFactor: 0.0,
            maxInterval: nil
        )

        // when
        let results = (0 ..< 4).compactMap { sut.delay(forRetry: UInt($0)) }

        // then
        XCTAssertEqual(results, [1, 2, 4, 8])
    }

    func test_thatDelayDoesNotExceedMaxInterval() {
        // given
        sut = ExponentialDelayStrategy(
            duration: .nanoseconds(1),
            multiplier: 2.0,
            jitterFactor: 0.0,
            maxInterval: .nanoseconds(4)
        )

        // when
        let results = (0 ..< 4).compactMap { sut.delay(forRetry: UInt($0)) }

        // then
        XCTAssertEqual(results, [1, 2, 4, 4])
    }

    func test_thatDelayIsWithinJitterBounds() {
        // given
        let baseNanos: UInt64 = 1_000_000_000
        let jitterFactor = 0.2
        sut = ExponentialDelayStrategy(
            duration: .nanoseconds(Int(baseNanos)),
            multiplier: 1.0,
            jitterFactor: jitterFactor,
            maxInterval: nil
        )

        // when
        let results = (0 ..< 100).compactMap { sut.delay(forRetry: UInt($0)) }

        // then
        let lower = UInt64(Double(baseNanos) * (1 - jitterFactor))
        let upper = UInt64(Double(baseNanos) * (1 + jitterFactor))
        XCTAssertTrue(results.allSatisfy { $0 >= lower && $0 <= upper })
    }

    func test_thatDelayIsMaxInterval_whenBaseExceedsMaxInterval() {
        // given
        sut = ExponentialDelayStrategy(
            duration: .nanoseconds(100),
            multiplier: 10.0,
            jitterFactor: 0.0,
            maxInterval: .nanoseconds(50)
        )

        // when
        let result = sut.delay(forRetry: 2)

        // then
        XCTAssertEqual(result, 50)
    }

    func test_thatDelayIsUnbounded_whenMaxIntervalIsNil() {
        // given
        sut = ExponentialDelayStrategy(
            duration: .nanoseconds(1),
            multiplier: 2.0,
            jitterFactor: 0.0,
            maxInterval: nil
        )

        // when
        let results = (0 ..< 6).compactMap { sut.delay(forRetry: UInt($0)) }

        // then
        XCTAssertEqual(results, [1, 2, 4, 8, 16, 32])
    }
}
