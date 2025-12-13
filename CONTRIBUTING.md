# Contributing to Typhoon

First off, thank you for considering contributing to Typhoon! It's people like you that make Typhoon such a great tool.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
  - [Development Setup](#development-setup)
  - [Project Structure](#project-structure)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Improving Documentation](#improving-documentation)
  - [Submitting Code](#submitting-code)
- [Development Workflow](#development-workflow)
  - [Branching Strategy](#branching-strategy)
  - [Commit Guidelines](#commit-guidelines)
  - [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
  - [Swift Style Guide](#swift-style-guide)
  - [Code Quality](#code-quality)
  - [Testing Requirements](#testing-requirements)
- [Community](#community)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to nv3212@gmail.com.

## Getting Started

### Development Setup

1. **Fork the repository**
   ```bash
   # Click the "Fork" button on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/typhoon.git
   cd typhoon
   ```

3. **Set up the development environment**
   ```bash
   # Bootstrap the project
   make bootstrap
   ```

4. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

5. **Open the project in Xcode**
   ```bash
   open Package.swift
   ```

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report, please check the [existing issues](https://github.com/space-code/typhoon/issues) to avoid duplicates.

When creating a bug report, include:

- **Clear title** - Describe the issue concisely
- **Reproduction steps** - Detailed steps to reproduce the bug
- **Expected behavior** - What you expected to happen
- **Actual behavior** - What actually happened
- **Environment** - OS, Xcode version, Swift version
- **Code samples** - Minimal reproducible example
- **Error messages** - Complete error output if applicable

**Example:**
```markdown
**Title:** ExponentialWithJitter strategy returns incorrect delay

**Steps to reproduce:**
1. Create RetryPolicyService with exponentialWithJitter strategy
2. Set maxInterval to 30 seconds
3. Observe delays exceeding maxInterval

**Expected:** Delays should never exceed 30 seconds
**Actual:** Delays can reach 60+ seconds

**Environment:**
- iOS 16.0
- Xcode 15.3
- Swift 5.10

**Code:**
\`\`\`swift
let service = RetryPolicyService(
    strategy: .exponentialWithJitter(
        retry: 5,
        maxInterval: .seconds(30),
        duration: .seconds(1)
    )
)
\`\`\`
```

### Suggesting Features

We love feature suggestions! When proposing a new feature, include:

- **Problem statement** - What problem does this solve?
- **Proposed solution** - How should it work?
- **Alternatives** - What alternatives did you consider?
- **Use cases** - Real-world scenarios
- **API design** - Example code showing usage
- **Breaking changes** - Will this break existing code?

**Example:**
```markdown
**Feature:** Add adaptive retry strategy

**Problem:** Current strategies are static. Applications need dynamic adjustment based on error patterns.

**Solution:** Add `.adaptive()` strategy that adjusts backoff based on success/failure rates.

**API:**
\`\`\`swift
let service = RetryPolicyService(
    strategy: .adaptive(
        minRetry: 2,
        maxRetry: 10,
        adaptiveFactor: 1.5
    )
)
\`\`\`

**Use case:** Mobile app that needs aggressive retries on good connections but conservative retries on poor connections.
```

### Improving Documentation

Documentation improvements are always welcome:

- **Code comments** - Add/improve inline documentation
- **DocC documentation** - Enhance documentation articles
- **README** - Fix typos, add examples
- **Guides** - Write tutorials or how-to guides
- **API documentation** - Document public APIs

### Submitting Code

1. **Check existing work** - Look for related issues or PRs
2. **Discuss major changes** - Open an issue for large features
3. **Follow coding standards** - See [Coding Standards](#coding-standards)
4. **Write tests** - All code changes require tests
5. **Update documentation** - Keep docs in sync with code
6. **Create a pull request** - Use clear description

## Development Workflow

### Branching Strategy

We use a simplified branching model:

- **`main`** - Main development branch (all PRs target this)
- **`feature/*`** - New features
- **`fix/*`** - Bug fixes
- **`docs/*`** - Documentation updates
- **`refactor/*`** - Code refactoring
- **`test/*`** - Test improvements

**Branch naming examples:**
```bash
feature/adaptive-retry-strategy
fix/exponential-jitter-calculation
docs/update-quick-start-guide
refactor/simplify-delay-calculation
test/add-retry-sequence-tests
```

### Commit Guidelines

We use [Conventional Commits](https://www.conventionalcommits.org/) for clear, structured commit history.

**Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style (formatting, no logic changes)
- `refactor` - Code refactoring
- `test` - Adding or updating tests
- `chore` - Maintenance tasks
- `perf` - Performance improvements

**Scopes:**
- `core` - Core retry logic
- `strategy` - Retry strategies
- `service` - Retry service
- `sequence` - Retry sequence
- `deps` - Dependencies

**Examples:**
```bash
feat(strategy): add adaptive retry strategy

Implement adaptive strategy that adjusts retry behavior based on
success/failure patterns. Includes exponential backoff with dynamic
multiplier adjustment.

Closes #45

---

fix(strategy): correct maxInterval comparison in exponentialWithJitter

maxInterval was compared in seconds instead of nanoseconds, causing
delays to be capped incorrectly. Now properly converts maxInterval
to nanoseconds before comparison.

Fixes #67

---

docs(quick-start): add network request examples

Add practical examples showing retry usage with URLSession,
including error handling and response validation patterns.

---

test(sequence): increase coverage for retry sequence

Add tests for:
- Edge cases with zero retries
- Large retry counts
- Jitter randomization verification
```

**Commit message rules:**
- Use imperative mood ("add" not "added")
- Don't capitalize first letter
- No period at the end
- Keep subject line under 72 characters
- Separate subject from body with blank line
- Reference issues in footer

### Pull Request Process

1. **Update your branch**
   ```bash
   git checkout main
   git pull upstream main
   git checkout feature/your-feature
   git rebase main
   ```

2. **Run tests and checks**
   ```bash
   # Run all tests
   swift test
   
   # Check test coverage
   swift test --enable-code-coverage
   ```

3. **Push to your fork**
   ```bash
   git push origin feature/your-feature
   ```

4. **Create pull request**
   - Target the `main` branch
   - Provide clear description
   - Link related issues
   - Include examples if applicable
   - Request review from maintainers

5. **Review process**
   - Address review comments
   - Keep PR up to date with main
   - Squash commits if requested
   - Wait for CI to pass

6. **After merge**
   ```bash
   # Clean up local branch
   git checkout main
   git pull upstream main
   git branch -d feature/your-feature
   
   # Clean up remote branch
   git push origin --delete feature/your-feature
   ```

## Coding Standards

### Swift Style Guide

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) and [Ray Wenderlich Swift Style Guide](https://github.com/raywenderlich/swift-style-guide).

**Key points:**

1. **Naming**
   ```swift
   // ✅ Good
   func retry<T>(_ operation: () async throws -> T) async throws -> T
   let retryCount: Int
   
   // ❌ Bad
   func doRetry(_ op: () async throws -> Any) async throws -> Any
   let cnt: Int
   ```

2. **Protocols**
   ```swift
   // ✅ Good - Use "I" prefix for protocols
   protocol IRetryStrategy {
       func calculateDelay(for attempt: Int) -> TimeInterval
   }
   
   // ❌ Bad
   protocol RetryStrategy { }
   ```

3. **Access Control**
   ```swift
   // ✅ Good - Explicit access control
   public struct RetryPolicyService {
       private let strategy: RetryStrategy
       
       public init(strategy: RetryStrategy) {
           self.strategy = strategy
       }
       
       public func retry<T>(
           _ operation: @escaping () async throws -> T
       ) async throws -> T {
           // Implementation
       }
   }
   ```

4. **Documentation**
   ```swift
   /// Executes an operation with automatic retry on failure.
   ///
   /// This service implements configurable retry strategies including
   /// constant delays, exponential backoff, and jitter randomization.
   ///
   /// - Parameter operation: The async operation to retry
   /// - Returns: The result of the successful operation
   /// - Throws: The last error if all retry attempts fail
   ///
   /// - Example:
   /// ```swift
   /// let service = RetryPolicyService(
   ///     strategy: .exponential(retry: 3, duration: .seconds(1))
   /// )
   /// let data = try await service.retry {
   ///     try await fetchData()
   /// }
   /// ```
   public func retry<T>(
       _ operation: @escaping () async throws -> T
   ) async throws -> T {
       // Implementation
   }
   ```

### Code Quality

- **No force unwrapping** - Use optional binding or guards
- **No force casting** - Use conditional casting
- **No magic numbers** - Use named constants
- **Single responsibility** - One class, one purpose
- **DRY principle** - Don't repeat yourself
- **SOLID principles** - Follow SOLID design

**Example:**
```swift
// ✅ Good
private enum RetryConstants {
    static let defaultMultiplier = 2.0
    static let nanosecPerSecond = 1_000_000_000.0
}

guard let durationSeconds = duration.double else {
    return .zero
}

// ❌ Bad
let duration = interval.double!
if duration * 1_000_000_000 > 2.0 {
    // Magic numbers and force unwrap
}
```

### Testing Requirements

All code changes must include tests:

1. **Unit tests** - Test individual components
2. **Integration tests** - Test component interactions
3. **Edge cases** - Test boundary conditions
4. **Error handling** - Test failure scenarios
5. **Performance tests** - Test critical paths

**Coverage requirements:**
- New code: minimum 80% coverage
- Modified code: maintain or improve existing coverage
- Critical paths: 100% coverage

**Test structure:**
```swift
import XCTest
@testable import Typhoon

final class RetryPolicyServiceTests: XCTestCase {
    var sut: RetryPolicyService!
    
    override func setUp() {
        super.setUp()
        sut = RetryPolicyService(
            strategy: .constant(retry: 3, duration: .seconds(1))
        )
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Success Tests
    
    func testRetry_WithSuccessfulOperation_ReturnsResult() async throws {
        // Given
        let expectedValue = 42
        
        // When
        let result = try await sut.retry {
            return expectedValue
        }
        
        // Then
        XCTAssertEqual(result, expectedValue)
    }
    
    // MARK: - Failure Tests
    
    func testRetry_WithAlwaysFailingOperation_ThrowsError() async {
        // Given
        let expectedError = TestError.failed
        
        // Then
        await XCTAssertThrowsError(
            try await sut.retry {
                throw expectedError
            }
        ) { error in
            XCTAssertEqual(error as? TestError, expectedError)
        }
    }
    
    // MARK: - Edge Cases
    
    func testRetry_WithZeroRetries_DoesNotRetry() async throws {
        // Given
        sut = RetryPolicyService(
            strategy: .constant(retry: 0, duration: .seconds(1))
        )
        var attemptCount = 0
        
        // When/Then
        await XCTAssertThrowsError(
            try await sut.retry {
                attemptCount += 1
                throw TestError.failed
            }
        )
        
        XCTAssertEqual(attemptCount, 1)
    }
}
```

## Community

- **Discussions** - Join [GitHub Discussions](https://github.com/space-code/typhoon/discussions)
- **Issues** - Track [open issues](https://github.com/space-code/typhoon/issues)
- **Pull Requests** - Review [open PRs](https://github.com/space-code/typhoon/pulls)

## Recognition

Contributors are recognized in:
- GitHub contributors page
- Release notes
- Project README (for significant contributions)

## Questions?

- Check [existing issues](https://github.com/space-code/typhoon/issues)
- Search [discussions](https://github.com/space-code/typhoon/discussions)
- Ask in [Q&A discussions](https://github.com/space-code/typhoon/discussions/categories/q-a)
- Email the maintainer: nv3212@gmail.com

---

Thank you for contributing to Typhoon! 🎉

Your efforts help make this project better for everyone.