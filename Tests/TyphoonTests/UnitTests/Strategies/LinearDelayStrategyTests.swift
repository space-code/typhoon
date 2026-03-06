//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

@testable import Typhoon
import XCTest

final class LinearDelayStrategyTests: XCTestCase {
    // MARK: - Properties

    private var sut: LinearDelayStrategy!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        sut = LinearDelayStrategy(duration: .seconds(1))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_thatDelayIncreasesLinearly() {
        // given
        let first = sut.delay(forRetry: 0)
        let second = sut.delay(forRetry: 1)
        let third = sut.delay(forRetry: 2)

        // then
        XCTAssertEqual(first, 1_000_000_000)
        XCTAssertEqual(second, 2_000_000_000)
        XCTAssertEqual(third, 3_000_000_000)
    }

    func test_thatDelayIsZero_whenDurationConversionFails() {
        // given
        sut = LinearDelayStrategy(duration: .never)

        // when
        let delay = sut.delay(forRetry: 0)

        // then
        XCTAssertEqual(delay, .zero)
    }
}
