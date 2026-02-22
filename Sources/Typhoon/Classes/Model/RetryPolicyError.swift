//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Foundation

/// `RetryPolicyError` is the error type returned by Typhoon.
public enum RetryPolicyError: Error {
    /// The retry limit for attempts to perform a request has been exceeded.
    case retryLimitExceeded
    /// Thrown when the total allowed duration for retries has been exceeded.
    case totalDurationExceeded
}
