//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Typhoon
import XCTest

// MARK: - RetryPolicyServiceTests

final class RetryPolicyServiceTests: XCTestCase {
    // MARK: Properties

    private var sut: IRetryPolicyService!

    // MARK: Lifecycle

    override func setUp() {
        super.setUp()
        sut = RetryPolicyService(strategy: .constant(retry: .defaultRetryCount, duration: .seconds(0)))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: Tests - Error Handling

    func test_thatRetryThrowsRetryLimitExceededError_whenAllRetriesFail() async throws {
        // given
        let expectedError = RetryPolicyError.retryLimitExceeded

        // when
        var receivedError: Error?
        do {
            _ = try await sut.retry { throw URLError(.unknown) }
        } catch {
            receivedError = error
        }

        // then
        XCTAssertEqual(receivedError as? NSError, expectedError as NSError)
    }

    func test_thatRetryThrowsOriginalError_whenOnFailureReturnsFalse() async throws {
        // given
        let originalError = URLError(.timedOut)

        // when
        var receivedError: Error?
        do {
            _ = try await sut.retry(
                strategy: .constant(retry: .defaultRetryCount, duration: .nanoseconds(1)),
                onFailure: { _ in false }
            ) {
                throw originalError
            }
        } catch {
            receivedError = error
        }

        // then
        XCTAssertEqual(receivedError as? URLError, originalError)
    }

    // MARK: Tests - Success Cases

    func test_thatRetryReturnsValue_whenOperationSucceedsImmediately() async throws {
        // given
        let expectedValue = 42

        // when
        let result = try await sut.retry {
            expectedValue
        }

        // then
        XCTAssertEqual(result, expectedValue)
    }

    func test_thatRetryReturnsValue_whenOperationSucceedsAfterRetries() async throws {
        // given
        let counter = Counter()
        let expectedValue = 100

        // when
        let result = try await sut.retry(
            strategy: .constant(retry: .defaultRetryCount, duration: .nanoseconds(1))
        ) {
            let currentCount = await counter.increment()

            if currentCount >= .defaultRetryCount {
                return expectedValue
            }
            throw URLError(.unknown)
        }

        // then
        XCTAssertEqual(result, expectedValue)
        let finalCount = await counter.getValue()
        XCTAssertEqual(finalCount, .defaultRetryCount)
    }

    // MARK: Tests - Retry Count

    func test_thatRetryAttemptsCorrectNumberOfTimes_whenAllRetriesFail() async throws {
        // given
        let counter = Counter()

        // when
        do {
            _ = try await sut.retry(
                strategy: .constant(retry: .defaultRetryCount, duration: .nanoseconds(1))
            ) {
                _ = await counter.increment()
                throw URLError(.unknown)
            }
        } catch {}

        // then
        let attemptCount = await counter.getValue()
        XCTAssertEqual(attemptCount, .defaultRetryCount + 1)
    }

    func test_thatRetryStopsImmediately_whenOnFailureReturnsFalse() async throws {
        // given
        let counter = Counter()

        // when
        do {
            _ = try await sut.retry(
                strategy: .constant(retry: .defaultRetryCount, duration: .nanoseconds(1)),
                onFailure: { _ in false }
            ) {
                _ = await counter.increment()
                throw URLError(.unknown)
            }
        } catch {}

        // then
        let attemptCount = await counter.getValue()
        XCTAssertEqual(attemptCount, 1)
    }

    // MARK: Tests - Failure Callback

    func test_thatRetryInvokesOnFailureCallback_whenErrorOccurs() async {
        // given
        let errorContainer = ErrorContainer()
        let expectedError = URLError(.notConnectedToInternet)

        // when
        do {
            _ = try await sut.retry(
                strategy: .constant(retry: .defaultRetryCount, duration: .nanoseconds(1)),
                onFailure: { error in
                    await errorContainer.setError(error as NSError)
                    return false
                }
            ) {
                throw expectedError
            }
        } catch {}

        // then
        let capturedError = await errorContainer.getError()
        XCTAssertEqual(capturedError as? URLError, expectedError)
    }

    func test_thatRetryInvokesOnFailureMultipleTimes_whenMultipleRetriesFail() async {
        // given
        let counter = Counter()
        let expectedCallCount = 3

        // when
        do {
            _ = try await sut.retry(
                strategy: .constant(retry: expectedCallCount, duration: .nanoseconds(1)),
                onFailure: { _ in
                    true
                }
            ) {
                _ = await counter.increment()
                throw URLError(.unknown)
            }
        } catch {}

        // then
        let callCount = await counter.getValue()
        XCTAssertEqual(callCount, expectedCallCount + 1)
    }

    // MARK: Tests - Edge Cases

    func test_thatRetryReturnsValue_whenRetryCountIsZero() async throws {
        // given
        let expectedValue = 7
        let zeroRetryStrategy = RetryPolicyService(
            strategy: .constant(retry: 0, duration: .nanoseconds(1))
        )

        // when
        let result = try await zeroRetryStrategy.retry {
            expectedValue
        }

        // then
        XCTAssertEqual(result, expectedValue)
    }

    func test_thatRetryThrowsError_whenRetryCountIsZeroAndOperationFails() async throws {
        // given
        let zeroRetryStrategy = RetryPolicyService(
            strategy: .constant(retry: 0, duration: .nanoseconds(1))
        )

        // when
        var receivedError: Error?
        do {
            _ = try await zeroRetryStrategy.retry {
                throw URLError(.badURL)
            }
        } catch {
            receivedError = error
        }

        // then
        XCTAssertNotNil(receivedError)
    }

    func test_thatRetryHandlesDifferentErrorTypes_whenMultipleErrorsOccur() async {
        // given
        let errorContainer = ErrorContainer()
        let counter = Counter()
        let errors: [Error] = [
            URLError(.badURL),
            URLError(.timedOut),
            URLError(.cannotFindHost),
        ]

        // when
        do {
            _ = try await sut.retry(
                strategy: .constant(retry: errors.count, duration: .nanoseconds(1)),
                onFailure: { error in
                    await errorContainer.setError(error as NSError)
                    return true
                }
            ) {
                let index = await counter.increment() - 1
                throw errors[min(index, errors.count - 1)]
            }
        } catch {}

        // then
        let lastError = await errorContainer.getError()
        XCTAssertNotNil(lastError)
    }
}

// MARK: - Counter

private actor Counter {
    // MARK: Properties

    private var value: Int = 0

    // MARK: Internal

    func increment() -> Int {
        value += 1
        return value
    }

    func getValue() -> Int {
        value
    }
}

// MARK: - ErrorContainer

private actor ErrorContainer {
    // MARK: Properties

    private var error: NSError?

    // MARK: Internal

    func setError(_ newError: NSError) {
        error = newError
    }

    func getError() -> NSError? {
        error
    }
}

// MARK: - Constants

private extension Int {
    static let defaultRetryCount = 5
}
