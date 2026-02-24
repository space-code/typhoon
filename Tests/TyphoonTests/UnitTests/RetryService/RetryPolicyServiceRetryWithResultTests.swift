//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

@testable import Typhoon
import XCTest

// MARK: - RetryPolicyServiceRetryWithResultTests

final class RetryPolicyServiceRetryWithResultTests: XCTestCase {
    // MARK: - Properties

    private enum TestError: Error, Equatable {
        case transient
        case fatal
    }

    // MARK: Tests

    func test_retryWithResult_succeedsOnFirstAttempt() async throws {
        // given
        let sut = RetryPolicyService(strategy: .constant(retry: 3, dispatchDuration: .milliseconds(10)))

        // when
        let result = try await sut.retryWithResult {
            42
        }

        // then
        XCTAssertEqual(result.value, 42)
        XCTAssertEqual(result.attempts, 1)
        XCTAssertTrue(result.errors.isEmpty)
        XCTAssertGreaterThanOrEqual(result.totalDuration, 0)
    }

    func test_retryWithResult_succeedsAfterSeveralFailures() async throws {
        // given
        let sut = RetryPolicyService(strategy: .constant(retry: 5, dispatchDuration: .milliseconds(10)))

        let counter = Counter()

        // when
        let result = try await sut.retryWithResult {
            counter.increment()
            if counter.value < 3 {
                throw TestError.transient
            }
            return "ok"
        }

        // then
        XCTAssertEqual(result.value, "ok")
        XCTAssertEqual(result.attempts, 3)
        XCTAssertEqual(result.errors.count, 2)
        XCTAssertTrue(result.errors.allSatisfy { ($0 as? TestError) == .transient })
    }

    func test_retryWithResult_throwsRetryLimitExceeded_whenAllAttemptsFail() async throws {
        // given
        let sut = RetryPolicyService(strategy: .constant(retry: 3, dispatchDuration: .milliseconds(10)))

        // when
        do {
            _ = try await sut.retryWithResult {
                throw TestError.transient
            }
            XCTFail("Expected RetryPolicyError.retryLimitExceeded to be thrown")
        } catch RetryPolicyError.retryLimitExceeded {}
    }

    func test_retryWithResult_stopsRetrying_whenOnFailureReturnsFalse() async throws {
        // given
        let sut = RetryPolicyService(strategy: .constant(retry: 5, dispatchDuration: .milliseconds(10)))

        let counter = Counter()

        // when
        do {
            _ = try await sut.retryWithResult(
                onFailure: { _ in false }
            ) {
                counter.increment()
                throw TestError.fatal
            }
            XCTFail("Expected error to be rethrown")
        } catch {
            XCTAssertEqual(error as? TestError, .fatal)
            let count = counter.value
            XCTAssertEqual(count, 1)
        }
    }

    func test_retryWithResult_stopsRetrying_onSpecificError() async throws {
        // given
        let sut = RetryPolicyService(strategy: .constant(retry: 5, dispatchDuration: .milliseconds(10)))

        let counter = Counter()

        // when
        do {
            _ = try await sut.retryWithResult(
                onFailure: { error in
                    (error as? TestError) == .transient
                }
            ) {
                counter.increment()
                let current = counter.value
                throw current == 1 ? TestError.transient : TestError.fatal
            }
            XCTFail("Expected error to be rethrown")
        } catch {
            XCTAssertEqual(error as? TestError, .fatal)
            let count = counter.value
            XCTAssertEqual(count, 2)
        }
    }

    func test_retryWithResult_onFailureReceivesAllErrors() async throws {
        // given
        let sut = RetryPolicyService(strategy: .constant(retry: 4, dispatchDuration: .milliseconds(10)))

        let counter = Counter()
        let receivedErrors = ErrorCollector()

        // when
        let result = try await sut.retryWithResult(
            onFailure: { error in
                await receivedErrors.append(error)
                return true
            }
        ) {
            counter.increment()
            if counter.value < 4 {
                throw TestError.transient
            }
            return "done"
        }

        // then
        XCTAssertEqual(result.value, "done")
        let collected = await receivedErrors.errors
        XCTAssertEqual(collected.count, 3)
        XCTAssertEqual(result.errors.count, 3)
    }

    func test_retryWithResult_customStrategyOverridesDefault() async throws {
        // given
        let sut = RetryPolicyService(strategy: .constant(retry: 10, dispatchDuration: .milliseconds(10)))
        let customStrategy = RetryPolicyStrategy.constant(retry: 2, dispatchDuration: .milliseconds(10))

        let counter = Counter()

        // when
        do {
            _ = try await sut.retryWithResult(strategy: customStrategy) {
                counter.increment()
                throw TestError.transient
            }
            XCTFail("Expected retryLimitExceeded")
        } catch RetryPolicyError.retryLimitExceeded {
            let count = counter.value
            XCTAssertLessThanOrEqual(count, 3)
        }
    }

    func test_retryWithResult_totalDurationIsNonNegative() async throws {
        // given
        let sut = RetryPolicyService(strategy: .constant(retry: 3, dispatchDuration: .milliseconds(10)))

        let counter = Counter()

        // when
        let result = try await sut.retryWithResult {
            counter.increment()
            if counter.value < 2 { throw TestError.transient }
            return true
        }

        // then
        XCTAssertGreaterThanOrEqual(result.totalDuration, 0)
    }
}

// MARK: - ErrorCollector

/// Actor-based collector to safely accumulate errors across concurrent closures.
private actor ErrorCollector {
    private(set) var errors: [Error] = []

    func append(_ error: Error) {
        errors.append(error)
    }
}
