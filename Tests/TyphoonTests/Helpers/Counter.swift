//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

import Foundation

final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: UInt = 0

    var value: UInt {
        lock.withLock { _value }
    }

    @discardableResult
    func increment() -> UInt {
        lock.withLock {
            _value += 1
            return _value
        }
    }

    @discardableResult
    func getValue() -> UInt {
        lock.withLock {
            _value
        }
    }
}
