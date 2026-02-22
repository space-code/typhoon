//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

extension Double {
    var safeUInt64: UInt64 {
        if self >= Double(UInt64.max) { return UInt64.max }
        if self <= 0 { return .zero }
        return UInt64(self)
    }
}
