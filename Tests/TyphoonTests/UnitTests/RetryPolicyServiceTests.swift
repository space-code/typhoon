//
// Typhoon
// Copyright © 2024 Space Code. All rights reserved.
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
        actor Counter {
            // MARK: Properties

            private var value: Int = 0

            // MARK: Internal

            func increment() -> Int {
                value += 1
                return value
            }
        }

        let counter = Counter()

        // when
        _ = try await sut.retry(
            strategy: .constant(retry: .retry, duration: .nanoseconds(1)),
            {
                let currentCounter = await counter.increment()

                if currentCounter > .retry - 1 {
                    return 1
                }
                throw URLError(.unknown)
            }
        )

        // then
        let finalValue = await counter.increment() - 1
        XCTAssertEqual(finalValue, .retry)
    }

    func test_thatRetryServiceHandlesErrorOnFailureCallback_whenErrorOcurred() async {
        // given
        actor ErrorContainer {
            // MARK: Private

            private var error: NSError?

            // MARK: Internal

            func setError(_ newError: NSError) {
                error = newError
            }

            func getError() -> NSError? {
                error
            }
        }

        let errorContainer = ErrorContainer()

        // when
        do {
            _ = try await sut.retry(
                strategy: .constant(retry: .retry, duration: .nanoseconds(1)),
                onFailure: { error in await errorContainer.setError(error as NSError) }
            ) {
                throw URLError(.unknown)
            }
        } catch {}

        // then
        let capturedError = await errorContainer.getError()
        XCTAssertEqual(capturedError as? URLError, URLError(.unknown))
    }
}

// MARK: - Constants

private extension Int {
    static let retry = 5
}
