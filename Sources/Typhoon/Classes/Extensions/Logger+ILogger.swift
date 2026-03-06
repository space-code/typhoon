//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

#if canImport(OSLog)
    import OSLog

    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
    extension Logger: ILogger {
        public func info(_ message: String) {
            info("\(message, privacy: .public)")
        }

        public func warning(_ message: String) {
            warning("\(message, privacy: .public)")
        }

        public func error(_ message: String) {
            error("\(message, privacy: .public)")
        }
    }
#endif
