//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Foundation

// MARK: - IRetryPolicyService

/// A type that defines a service for retry policies
public protocol IRetryPolicyService: Sendable {
    /// Retries a closure with a given strategy.
    ///
    /// - Parameters:
    ///   - strategy: The strategy defining the behavior of the retry policy.
    ///   - onFailure: An optional closure called on each failure to handle or log errors.
    ///   - closure: The closure that will be retried based on the specified strategy.
    ///
    /// - Returns: The result of the closure's execution after retrying based on the policy.
    func retry<T>(
        strategy: RetryPolicyStrategy?,
        onFailure: (@Sendable (Error) async -> Void)?,
        _ closure: @Sendable () async throws -> T
    ) async throws -> T
}

public extension IRetryPolicyService {
    /// Retries a closure with a given strategy.
    ///
    /// - Parameters:
    ///   - closure: The closure that will be retried based on the specified strategy.
    ///
    /// - Returns: The result of the closure's execution after retrying based on the policy.
    func retry<T>(_ closure: @Sendable () async throws -> T) async throws -> T {
        try await retry(strategy: nil, onFailure: nil, closure)
    }

    /// Retries a closure with a given strategy.
    ///
    /// - Parameters:
    ///   - strategy: The strategy defining the behavior of the retry policy.
    ///   - closure: The closure that will be retried based on the specified strategy.
    ///
    /// - Returns: The result of the closure's execution after retrying based on the policy.
    func retry<T>(strategy: RetryPolicyStrategy?, _ closure: @Sendable () async throws -> T) async throws -> T {
        try await retry(strategy: strategy, onFailure: nil, closure)
    }
}
