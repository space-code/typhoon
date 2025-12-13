//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Foundation

extension DispatchTimeInterval {
    /// Converts a `DispatchTimeInterval` value into seconds represented as `Double`.
    ///
    /// This computed property normalizes all supported `DispatchTimeInterval` cases
    /// (`seconds`, `milliseconds`, `microseconds`, `nanoseconds`) into a single
    /// unit — **seconds** — which simplifies time calculations and conversions.
    ///
    /// For example:
    /// - `.seconds(2)` → `2.0`
    /// - `.milliseconds(500)` → `0.5`
    /// - `.microseconds(1_000)` → `0.001`
    /// - `.nanoseconds(1_000_000_000)` → `1.0`
    ///
    /// - Returns: The interval expressed in seconds as `Double`,
    ///   or `nil` if the interval represents `.never` or an unknown case.
    var double: Double? {
        switch self {
        case let .seconds(value):
            return Double(value)
        case let .milliseconds(value):
            return Double(value) * 1e-3
        case let .microseconds(value):
            return Double(value) * 1e-6
        case let .nanoseconds(value):
            return Double(value) * 1e-9
        case .never:
            return nil
        @unknown default:
            return nil
        }
    }
}
