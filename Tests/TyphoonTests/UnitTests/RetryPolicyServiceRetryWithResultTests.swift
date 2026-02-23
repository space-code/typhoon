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

    // MARK: - Counter

    private actor Counter {
        private(set) var count: Int = 0

        func increment() {
            count += 1
        }
    }

    // MARK: Tests

    func test_retryWithResult_succeedsOnFirstAttempt() async throws {
        let sut = RetryPolicyService(strategy: .constant(retry: 3, duration: .milliseconds(10)))

        let result = try await sut.retryWithResult {
            42
        }

        XCTAssertEqual(result.value, 42)
        XCTAssertEqual(result.attempts, 1)
        XCTAssertTrue(result.errors.isEmpty)
        XCTAssertGreaterThanOrEqual(result.totalDuration, 0)
    }

    func test_retryWithResult_succeedsAfterSeveralFailures() async throws {
        let sut = RetryPolicyService(strategy: .constant(retry: 5, duration: .milliseconds(10)))

        let counter = Counter()

        let result = try await sut.retryWithResult {
            await counter.increment()
            if await counter.count < 3 {
                throw TestError.transient
            }
            return "ok"
        }

        XCTAssertEqual(result.value, "ok")
        XCTAssertEqual(result.attempts, 3)
        XCTAssertEqual(result.errors.count, 2)
        XCTAssertTrue(result.errors.allSatisfy { ($0 as? TestError) == .transient })
    }

    func test_retryWithResult_throwsRetryLimitExceeded_whenAllAttemptsFail() async throws {
        let sut = RetryPolicyService(strategy: .constant(retry: 3, duration: .milliseconds(10)))

        do {
            _ = try await sut.retryWithResult {
                throw TestError.transient
            }
            XCTFail("Expected RetryPolicyError.retryLimitExceeded to be thrown")
        } catch RetryPolicyError.retryLimitExceeded {}
    }

    func test_retryWithResult_stopsRetrying_whenOnFailureReturnsFalse() async throws {
        let sut = RetryPolicyService(strategy: .constant(retry: 5, duration: .milliseconds(10)))

        let counter = Counter()

        do {
            _ = try await sut.retryWithResult(
                onFailure: { _ in false }
            ) {
                await counter.increment()
                throw TestError.fatal
            }
            XCTFail("Expected error to be rethrown")
        } catch {
            XCTAssertEqual(error as? TestError, .fatal)
            let count = await counter.count
            XCTAssertEqual(count, 1)
        }
    }

    func test_retryWithResult_stopsRetrying_onSpecificError() async throws {
        let sut = RetryPolicyService(strategy: .constant(retry: 5, duration: .milliseconds(10)))

        let counter = Counter()

        do {
            _ = try await sut.retryWithResult(
                onFailure: { error in
                    (error as? TestError) == .transient
                }
            ) {
                await counter.increment()
                let current = await counter.count
                throw current == 1 ? TestError.transient : TestError.fatal
            }
            XCTFail("Expected error to be rethrown")
        } catch {
            XCTAssertEqual(error as? TestError, .fatal)
            let count = await counter.count
            XCTAssertEqual(count, 2)
        }
    }

    func test_retryWithResult_onFailureReceivesAllErrors() async throws {
        let sut = RetryPolicyService(strategy: .constant(retry: 4, duration: .milliseconds(10)))

        let counter = Counter()
        let receivedErrors = ErrorCollector()

        let result = try await sut.retryWithResult(
            onFailure: { error in
                await receivedErrors.append(error)
                return true
            }
        ) {
            await counter.increment()
            if await counter.count < 4 {
                throw TestError.transient
            }
            return "done"
        }

        XCTAssertEqual(result.value, "done")
        let collected = await receivedErrors.errors
        XCTAssertEqual(collected.count, 3)
        XCTAssertEqual(result.errors.count, 3)
    }

    func test_retryWithResult_customStrategyOverridesDefault() async throws {
        let sut = RetryPolicyService(strategy: .constant(retry: 10, duration: .milliseconds(10)))
        let customStrategy = RetryPolicyStrategy.constant(retry: 2, duration: .milliseconds(10))

        let counter = Counter()

        do {
            _ = try await sut.retryWithResult(strategy: customStrategy) {
                await counter.increment()
                throw TestError.transient
            }
            XCTFail("Expected retryLimitExceeded")
        } catch RetryPolicyError.retryLimitExceeded {
            let count = await counter.count
            XCTAssertLessThanOrEqual(count, 3)
        }
    }

    func test_retryWithResult_totalDurationIsNonNegative() async throws {
        let sut = RetryPolicyService(strategy: .constant(retry: 3, duration: .milliseconds(10)))

        let counter = Counter()

        let result = try await sut.retryWithResult {
            await counter.increment()
            if await counter.count < 2 { throw TestError.transient }
            return true
        }

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
