//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Foundation

extension DispatchTimeInterval {
    /// Converts a `DispatchTimeInterval` value into nanoseconds represented as `UInt64`.
    ///
    /// - Returns: The interval expressed in nanoseconds,
    ///   or `nil` if the interval represents `.never` or an unknown case.
    var nanoseconds: UInt64? {
        switch self {
        case let .seconds(value):
            return UInt64(value) * 1_000_000_000
        case let .milliseconds(value):
            return UInt64(value) * 1_000_000
        case let .microseconds(value):
            return UInt64(value) * 1000
        case let .nanoseconds(value):
            return UInt64(value)
        case .never:
            return nil
        @unknown default:
            return nil
        }
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    static func from(_ duration: Duration) -> DispatchTimeInterval {
        let seconds = duration.components.seconds
        let nanos = duration.components.attoseconds / 1_000_000_000
        let totalNanos = Int(seconds) * 1_000_000_000 + Int(nanos)
        return .nanoseconds(totalNanos)
    }
}
