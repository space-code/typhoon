//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

import Foundation
@testable import Typhoon
import XCTest

// MARK: - RetryPolicyServiceLoggerTests

final class RetryPolicyServiceLoggerTests: XCTestCase {
    private var logger: MockLogger!

    override func setUp() {
        super.setUp()
        logger = MockLogger()
    }

    override func tearDown() {
        logger = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_logsNothing_onFirstAttemptSuccess() async throws {
        // given
        let sut = makeSUT()

        // when
        _ = try await sut.retry(strategy: nil, onFailure: nil) { 42 }

        // then
        XCTAssertTrue(logger.entries.isEmpty)
    }

    func test_logsWarning_onEachFailedAttempt() async {
        // given
        let sut = makeSUT(retry: 3)
        let attempt = Counter()

        // when
        _ = try? await sut.retry(strategy: nil, onFailure: nil) {
            attempt.increment()
            if attempt.value < 3 { throw URLError(.notConnectedToInternet) }
            return 42
        }

        // then
        XCTAssertEqual(logger.warningMessages.count, 2)
        XCTAssertTrue(logger.warningMessages.allSatisfy { $0.contains("[RetryPolicy]") })
    }

    func test_logsInfo_onSuccessAfterRetry() async throws {
        let sut = makeSUT(retry: 3)
        let attempt = Counter()

        _ = try await sut.retry(strategy: nil, onFailure: nil) {
            attempt.increment()
            if attempt.value < 2 { throw URLError(.notConnectedToInternet) }
            return 42
        }

        XCTAssertTrue(logger.infoMessages.contains { $0.contains("Succeeded after 2 attempt(s)") })
    }

    func test_logsError_onRetryLimitExceeded() async {
        // given
        let sut = makeSUT(retry: 2)

        // when
        _ = try? await sut.retry(strategy: nil, onFailure: nil) {
            throw URLError(.notConnectedToInternet)
        }

        // then
        XCTAssertTrue(logger.errorMessages.contains { $0.contains("Retry limit exceeded") })
    }

    func test_logsWarning_whenOnFailureStopsRetrying() async {
        // given
        let sut = makeSUT(retry: 5)

        // when
        _ = try? await sut.retry(
            strategy: nil,
            onFailure: { _ in false }
        ) {
            throw URLError(.badServerResponse)
        }

        // then
        XCTAssertTrue(logger.warningMessages.contains { $0.contains("onFailure returned false") })
    }

    func test_logsError_onTotalDurationExceeded() async {
        // given
        let sut = makeSUT(retry: 10, maxTotalDuration: .milliseconds(1))

        // when
        try? await Task.sleep(nanoseconds: 2_000_000)

        _ = try? await sut.retry(strategy: nil, onFailure: nil) {
            throw URLError(.timedOut)
        }

        // then
        XCTAssertTrue(logger.errorMessages.contains { $0.contains("Total duration exceeded") })
    }

    func test_logsWarning_withFailedAttemptNumber() async {
        // given
        let sut = makeSUT(retry: 3)
        let attempt = Counter()

        // when
        _ = try? await sut.retry(strategy: nil, onFailure: nil) {
            attempt.increment()
            throw URLError(.notConnectedToInternet)
        }

        // then
        XCTAssertTrue(logger.warningMessages.first?.contains("Attempt 1") == true)
        XCTAssertTrue(logger.warningMessages.dropFirst().first?.contains("Attempt 2") == true)
        XCTAssertTrue(logger.warningMessages.dropFirst(2).first?.contains("Attempt 3") == true)
    }
}

// MARK: - Helpers

private extension RetryPolicyServiceLoggerTests {
    func makeSUT(
        retry: UInt = 3,
        maxTotalDuration: DispatchTimeInterval? = nil
    ) -> RetryPolicyService {
        RetryPolicyService(
            strategy: .constant(retry: retry, dispatchDuration: .milliseconds(1)),
            maxTotalDuration: maxTotalDuration,
            logger: logger
        )
    }
}
