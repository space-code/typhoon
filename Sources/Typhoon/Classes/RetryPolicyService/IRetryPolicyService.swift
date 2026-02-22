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
        onFailure: (@Sendable (Error) async -> Bool)?,
        _ closure: @Sendable () async throws -> T
    ) async throws -> T

    /// Retries a closure and returns a detailed `RetryResult` including success/failure info.
    ///
    /// - Parameters:
    ///   - strategy: Optional strategy that defines the retry behavior.
    ///   - onFailure: Optional closure called on each failure; returning `true` stops retries.
    ///   - closure: The async closure to be retried according to the strategy.
    ///
    /// - Returns: A `RetryResult` containing the final value, attempt count, total duration, and encountered errors.
    func retryWithResult<T>(
        strategy: RetryPolicyStrategy?,
        onFailure: (@Sendable (Error) async -> Bool)?,
        _ closure: @Sendable () async throws -> T
    ) async throws -> RetryResult<T>
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

    /// Retries a closure with a given strategy.
    ///
    /// - Parameters:
    ///   - onFailure: An optional closure called on each failure to handle or log errors.
    ///   - closure: The closure that will be retried based on the specified strategy.
    ///
    /// - Returns: The result of the closure's execution after retrying based on the policy.
    func retry<T>(_ closure: @Sendable () async throws -> T, onFailure: (@Sendable (Error) async -> Bool)?) async throws -> T {
        try await retry(strategy: nil, onFailure: onFailure, closure)
    }

    /// Retries a closure and returns a detailed `RetryResult` including success/failure info.
    ///
    /// - Parameters:
    ///   - closure: The async closure to be retried according to the strategy.
    ///
    /// - Returns: A `RetryResult` containing the final value, attempt count, total duration, and encountered errors.
    func retryWithResult<T>(
        _ closure: @Sendable () async throws -> T
    ) async throws -> RetryResult<T> {
        try await retryWithResult(strategy: nil, onFailure: nil, closure)
    }

    /// Retries a closure and returns a detailed `RetryResult` including success/failure info.
    ///
    /// - Parameters:
    ///   - onFailure: Optional closure called on each failure; returning `true` stops retries.
    ///   - closure: The async closure to be retried according to the strategy.
    ///
    /// - Returns: A `RetryResult` containing the final value, attempt count, total duration, and encountered errors.
    func retryWithResult<T>(
        onFailure: (@Sendable (Error) async -> Bool)?,
        _ closure: @Sendable () async throws -> T
    ) async throws -> RetryResult<T> {
        try await retryWithResult(strategy: nil, onFailure: onFailure, closure)
    }
}
