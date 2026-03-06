//
// Typhoon
// Copyright © 2026 Space Code. All rights reserved.
//

import Foundation

// MARK: - ILogger

/// A protocol that abstracts logging functionality.
///
/// Conform to this protocol to provide a custom logging implementation,
/// or use the built-in `Logger` wrapper on Apple platforms.
///
/// ### Example
/// ```swift
/// struct PrintLogger: ILogger {
///     func info(_ message: @autoclosure () -> String) {
///         print("[INFO] \(message())")
///     }
///     func warning(_ message: @autoclosure () -> String) {
///         print("[WARNING] \(message())")
///     }
///     func error(_ message: @autoclosure () -> String) {
///         print("[ERROR] \(message())")
///     }
/// }
/// ```
public protocol ILogger: Sendable {
    /// Logs an informational message.
    /// - Parameter message: A closure that returns the message string (evaluated lazily).
    func info(_ message: String)

    /// Logs a warning message.
    /// - Parameter message: A closure that returns the message string (evaluated lazily).
    func warning(_ message: String)

    /// Logs an error message.
    /// - Parameter message: A closure that returns the message string (evaluated lazily).
    func error(_ message: String)
}
