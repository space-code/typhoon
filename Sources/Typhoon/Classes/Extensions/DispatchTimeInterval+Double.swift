//
// Typhoon
// Copyright © 2023 Space Code. All rights reserved.
//

import Foundation

extension DispatchTimeInterval {
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
