//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Foundation

/// `RetryPolicyError` is the error type returned by Typhoon.
public enum RetryPolicyError: Error, Equatable {
    public static func == (lhs: RetryPolicyError, rhs: RetryPolicyError) -> Bool {
        switch (lhs, rhs) {
        case let (.retryLimitExceeded(lhsErrors), .retryLimitExceeded(rhsErrors)):
            lhsErrors.map { $0 as NSError } == rhsErrors.map { $0 as NSError }
        case (.totalDurationExceeded, .totalDurationExceeded):
            true
        default:
            false
        }
    }

    /// The retry limit for attempts to perform a request has been exceeded.
    case retryLimitExceeded(errors: [Error])
    /// Thrown when the total allowed duration for retries has been exceeded.
    case totalDurationExceeded
}
