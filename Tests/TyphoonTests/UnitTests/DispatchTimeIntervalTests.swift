//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

@testable import Typhoon
import XCTest

// MARK: - DispatchTimeIntervalTests

final class DispatchTimeIntervalTests: XCTestCase {
    func test_thatDispatchTimeIntervalConvertsMillisecondsToNanoseconds() {
        // given
        let interval = DispatchTimeInterval.milliseconds(.value)

        // when
        let result = interval.nanoseconds

        // then
        XCTAssertEqual(result, UInt64(Int.value) * 1_000_000)
    }

    func test_thatDispatchTimeIntervalConvertsSecondsToNanoseconds() {
        // given
        let interval = DispatchTimeInterval.seconds(.value)

        // when
        let result = interval.nanoseconds

        // then
        XCTAssertEqual(result, UInt64(Int.value) * 1_000_000_000)
    }

    func test_thatDispatchTimeIntervalConvertsMicrosecondsToNanoseconds() {
        // given
        let interval = DispatchTimeInterval.microseconds(.value)

        // when
        let result = interval.nanoseconds

        // then
        XCTAssertEqual(result, UInt64(Int.value) * 1000)
    }

    func test_thatDispatchTimeIntervalConvertsNanosecondsToNanoseconds() {
        // given
        let interval = DispatchTimeInterval.nanoseconds(.value)

        // when
        let result = interval.nanoseconds

        // then
        XCTAssertEqual(result, UInt64(Int.value))
    }

    func test_thatDispatchTimeIntervalReturnsNil_whenIntervalIsEqualToNever() {
        // given
        let interval = DispatchTimeInterval.never

        // when
        let result = interval.nanoseconds

        // then
        XCTAssertNil(result)
    }
}

// MARK: - Constants

private extension Int {
    static let value = 1000
}
