//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Typhoon
import XCTest

// MARK: - RetryPolicyServiceTests

final class RetryPolicyServiceTests: XCTestCase {
    // MARK: Private

    private var sut: IRetryPolicyService!

    // MARK: XCTestCase

    override func setUp() {
        super.setUp()
        sut = RetryPolicyService(strategy: .constant(retry: .retry, duration: .seconds(0)))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: Tests

    func test_thatRetryServiceThrowsAnError_whenRetryLimitExceeded() async throws {
        // when
        var receivedError: Error?
        do {
            _ = try await sut.retry { throw URLError(.unknown) }
        } catch {
            receivedError = error
        }

        // then
        XCTAssertEqual(receivedError as? NSError, RetryPolicyError.retryLimitExceeded as NSError)
    }

    func test_thatRetryServiceDoesNotThrowAnError_whenServiceDidReturnValue() async throws {
        // given
        var counter = 0

        // when
        _ = try await sut.retry(
            strategy: .constant(retry: .retry, duration: .nanoseconds(1)),
            {
                counter += 1

                if counter > .retry - 1 {
                    return 1
                }
                throw URLError(.unknown)
            }
        )

        // then
        XCTAssertEqual(counter, .retry)
    }
}

// MARK: - Constants

private extension Int {
    static let retry = 5
}
