//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Typhoon
import XCTest

// MARK: - RetryPolicyStrategyTests

final class RetryPolicyStrategyTests: XCTestCase {
    // MARK: Tests

    func test_thatRetryPolicyStrategyReturnsDuration_whenTypeIsConstant() {
        // when
        let duration = RetryPolicyStrategy.constant(retry: .retry, duration: .second).duration

        // then
        XCTAssertEqual(duration, .second)
    }

    func test_thatRetryPolicyStrategyReturnsDuration_whenTypeIsExponential() {
        // when
        let duration = RetryPolicyStrategy.exponential(retry: .retry, duration: .second).duration

        // then
        XCTAssertEqual(duration, .second)
    }

    func test_thatRetryPolicyStrategyReturnsDuration_whenTypeIsExponentialWithJitter() {
        // when
        let duration = RetryPolicyStrategy.exponentialWithJitter(retry: .retry, duration: .second).duration

        // then
        XCTAssertEqual(duration, .second)
    }
}

// MARK: Constants

private extension Int {
    static let retry = 5
}

private extension DispatchTimeInterval {
    static let second = DispatchTimeInterval.seconds(1)
}
