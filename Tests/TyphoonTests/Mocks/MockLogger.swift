//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

import Foundation
@testable import Typhoon

// MARK: - MockLogger

final class MockLogger: ILogger, @unchecked Sendable {
    // MARK: Types

    enum Level {
        case info, warning, error
    }

    struct LogEntry: Equatable {
        let level: Level
        let message: String
    }

    // MARK: Private

    private let lock = NSLock()
    private var _entries: [LogEntry] = []

    // MARK: Internal

    var entries: [LogEntry] {
        lock.withLock { _entries }
    }

    var infoMessages: [String] {
        entries.filter { $0.level == .info }.map(\.message)
    }

    var warningMessages: [String] {
        entries.filter { $0.level == .warning }.map(\.message)
    }

    var errorMessages: [String] {
        entries.filter { $0.level == .error }.map(\.message)
    }

    // MARK: ILogger

    func info(_ message: String) {
        lock.withLock { _entries.append(.init(level: .info, message: message)) }
    }

    func warning(_ message: String) {
        lock.withLock { _entries.append(.init(level: .warning, message: message)) }
    }

    func error(_ message: String) {
        lock.withLock { _entries.append(.init(level: .error, message: message)) }
    }
}
