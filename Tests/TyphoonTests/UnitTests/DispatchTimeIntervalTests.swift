//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

@testable import Typhoon
import XCTest

// MARK: - DispatchTimeIntervalTests

final class DispatchTimeIntervalTests: XCTestCase {
    func test_thatDispatchTimeIntervalConvertsMillisecondsToDouble() {
        // given
        let interval = DispatchTimeInterval.milliseconds(.value)

        // when
        let result = interval.double

        // then
        XCTAssertEqual(result, Double(Int.value) * 1e-3)
    }

    func test_thatDispatchTimeIntervalConvertsSecondsToDouble() {
        // given
        let interval = DispatchTimeInterval.seconds(.value)

        // when
        let result = interval.double

        // then
        XCTAssertEqual(result, Double(Int.value))
    }

    func test_thatDispatchTimeIntervalConvertsMicrosecondsToDouble() {
        // given
        let interval = DispatchTimeInterval.microseconds(.value)

        // when
        let result = interval.double

        // then
        XCTAssertEqual(result, Double(Int.value) * 1e-6)
    }

    func test_thatDispatchTimeIntervalConvertsNanosecondsToDouble() {
        // given
        let interval = DispatchTimeInterval.nanoseconds(.value)

        // when
        let result = interval.double

        // then
        XCTAssertEqual(result, Double(Int.value) * 1e-9)
    }

    func test_thatDispatchTimeIntervalReturnsNil_whenIntervalIsEqualToNever() {
        // given
        let interval = DispatchTimeInterval.never

        // when
        let result = interval.double

        // then
        XCTAssertNil(result)
    }
}

// MARK: - Constants

private extension Int {
    static let value = 1000
}
