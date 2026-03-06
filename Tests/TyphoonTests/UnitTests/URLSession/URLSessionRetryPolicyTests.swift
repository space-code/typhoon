//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

#if canImport(Darwin)
    @testable import Typhoon
    import XCTest

    // MARK: - URLSessionRetryPolicyTests

    final class URLSessionRetryPolicyTests: XCTestCase {
        // MARK: Properties

        private var sut: URLSession!

        // MARK: Setup

        override func setUp() async throws {
            try await super.setUp()
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            sut = URLSession(configuration: config)
            await MockURLProtocolHandler.shared.set(nil)
        }

        override func tearDown() async throws {
            sut = nil
            await MockURLProtocolHandler.shared.set(nil)
            try await super.tearDown()
        }

        // MARK: Tests

        func test_dataForRequest_succeedsOnFirstAttempt() async throws {
            // given
            let counter = Counter()

            await setHandler {
                counter.increment()
                return (.ok, Data(String.data.utf8))
            }

            // when
            let (data, _) = try await sut.data(
                for: .stub,
                retryPolicy: .constant(retry: 3, dispatchDuration: .milliseconds(1))
            )

            // then
            XCTAssertEqual(String(data: data, encoding: .utf8), String.data)
            XCTAssertEqual(counter.value, 1)
        }

        func test_dataForRequest_retriesAndSucceedsOnSecondAttempt() async throws {
            // given
            let counter = Counter()

            await setHandler {
                let count = counter.increment()
                if count < 2 { throw URLError(.notConnectedToInternet) }
                return (.ok, Data(String.data.utf8))
            }

            // when
            let (data, _) = try await sut.data(
                for: .stub,
                retryPolicy: .constant(retry: 3, dispatchDuration: .milliseconds(1))
            )

            // then
            XCTAssertEqual(counter.value, 2)
            XCTAssertEqual(String(data: data, encoding: .utf8), String.data)
        }

        func test_dataForRequest_throwsRetryLimitExceeded_whenAllAttemptsFail() async throws {
            // given
            await setHandler { throw URLError(.notConnectedToInternet) }

            // when / then
            do {
                _ = try await sut.data(
                    for: .stub,
                    retryPolicy: .constant(retry: 2, dispatchDuration: .milliseconds(1))
                )
                XCTFail("Expected RetryPolicyError.retryLimitExceeded to be thrown")
            } catch RetryPolicyError.retryLimitExceeded {
                // success
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        func test_dataForRequest_stopsRetrying_whenOnFailureReturnsFalse() async throws {
            // given
            let counter = Counter()

            await setHandler {
                counter.increment()
                throw URLError(.badServerResponse)
            }

            // when / then
            do {
                _ = try await sut.data(
                    for: .stub,
                    retryPolicy: .constant(retry: 5, dispatchDuration: .milliseconds(1)),
                    onFailure: { _ in false }
                )
                XCTFail("Expected URLError to be thrown")
            } catch is URLError {
                // success
            } catch {
                XCTFail("Unexpected error: \(error)")
            }

            XCTAssertEqual(counter.value, 1, "Should not retry when onFailure returns false")
        }

        func test_dataForRequest_onFailure_isCalledOnEachFailure() async throws {
            // given
            let counter = Counter()

            await setHandler { throw URLError(.notConnectedToInternet) }

            // when / then
            do {
                _ = try await sut.data(
                    for: .stub,
                    retryPolicy: .constant(retry: 3, dispatchDuration: .milliseconds(1)),
                    onFailure: { _ in
                        counter.increment()
                        return true
                    }
                )
                XCTFail("Expected RetryPolicyError.retryLimitExceeded to be thrown")
            } catch RetryPolicyError.retryLimitExceeded {
                // success
            } catch {
                XCTFail("Unexpected error: \(error)")
            }

            XCTAssertEqual(counter.value, 4)
        }

        func test_dataFromURL_retriesAndSucceeds() async throws {
            // given
            let counter = Counter()

            await setHandler {
                let count = counter.increment()
                if count < 3 { throw URLError(.timedOut) }
                return (.ok, Data(String.data.utf8))
            }

            let url = try XCTUnwrap(URL(string: "https://stub.test"))

            // when
            let (data, _) = try await sut.data(
                from: url,
                retryPolicy: .constant(retry: 3, dispatchDuration: .milliseconds(1))
            )

            // then
            XCTAssertEqual(counter.value, 3)
            XCTAssertEqual(String(data: data, encoding: .utf8), String.data)
        }

        #if !os(watchOS)
            func test_upload_succeedsAfterRetry() async throws {
                // given
                let counter = Counter()

                await setHandler {
                    let count = counter.increment()
                    if count < 2 { throw URLError(.networkConnectionLost) }
                    return (.ok, Data())
                }

                // when
                _ = try await sut.upload(
                    for: .stub,
                    from: Data(String.data.utf8),
                    retryPolicy: .constant(retry: 3, dispatchDuration: .milliseconds(1))
                )

                // then
                XCTAssertEqual(counter.value, 2)
            }
        #endif

        @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
        func test_download_succeedsAfterRetry() async throws {
            // given
            let counter = Counter()

            await setHandler {
                let count = counter.increment()
                if count < 2 { throw URLError(.timedOut) }
                return (.ok, Data(String.data.utf8))
            }

            // when
            let (url, _) = try await sut.download(
                for: .stub,
                retryPolicy: .constant(retry: 3, dispatchDuration: .milliseconds(1))
            )

            // then
            XCTAssertEqual(counter.value, 2)
            let content = try String(contentsOf: url, encoding: .utf8)
            XCTAssertEqual(content, String.data)
        }

        func test_linearStrategy_retriesCorrectNumberOfTimes() async throws {
            // given
            let counter = Counter()

            await setHandler {
                counter.increment()
                throw URLError(.notConnectedToInternet)
            }

            // when / then
            do {
                _ = try await sut.data(
                    for: .stub,
                    retryPolicy: .linear(retry: 4, dispatchDuration: .milliseconds(1))
                )
                XCTFail("Expected RetryPolicyError.retryLimitExceeded to be thrown")
            } catch RetryPolicyError.retryLimitExceeded {
                // success
            } catch {
                XCTFail("Unexpected error: \(error)")
            }

            XCTAssertEqual(counter.value, 5)
        }

        func test_chainStrategy_retriesCorrectNumberOfTimes() async throws {
            // given
            let counter = Counter()

            await setHandler {
                counter.increment()
                throw URLError(.notConnectedToInternet)
            }

            let strategy = RetryPolicyStrategy.chain([
                .init(retries: 2, strategy: ConstantDelayStrategy(duration: .milliseconds(1))),
                .init(retries: 3, strategy: ConstantDelayStrategy(duration: .milliseconds(1))),
            ])

            // when / then
            do {
                _ = try await sut.data(for: .stub, retryPolicy: strategy)
                XCTFail("Expected RetryPolicyError.retryLimitExceeded to be thrown")
            } catch RetryPolicyError.retryLimitExceeded {
                // success
            } catch {
                XCTFail("Unexpected error: \(error)")
            }

            XCTAssertEqual(counter.value, 6)
        }

        // MARK: Helpers

        private func setHandler(_ handler: MockURLProtocolHandler.Handler?) async {
            await MockURLProtocolHandler.shared.set(handler)
        }
    }

    // MARK: - Constants

    private extension HTTPURLResponse {
        static let ok = HTTPURLResponse(
            url: URL(string: "https://stub.test")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    private extension URLRequest {
        static let stub = URLRequest(url: URL(string: "https://stub.test")!)
    }

    private extension String {
        static let data = "hello"
    }
#endif
