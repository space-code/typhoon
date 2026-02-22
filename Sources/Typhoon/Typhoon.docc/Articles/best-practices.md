# Best Practices

Learn the recommended patterns and practices for using Typhoon effectively.

## Overview

This guide covers best practices, common pitfalls, and recommended patterns for implementing retry logic in production applications.

## Strategy Selection

### Choose Based on Use Case

Different scenarios require different retry strategies:

```swift
// ✅ Fast local operations (file I/O, cache)
let localRetry = RetryPolicyService(
    strategy: .constant(retry: 3, duration: .milliseconds(100))
)

// ✅ Standard API calls
let apiRetry = RetryPolicyService(
    strategy: .exponential(retry: 4, multiplier: 2.0, duration: .seconds(1))
)

// ✅ High-traffic services
let highTrafficRetry = RetryPolicyService(
    strategy: .exponential(
        retry: 5,
        jitterFactor: 0.2,
        maxInterval: 60,
        multiplier: 2.0,
        duration: .seconds(1)
    )
)

// ❌ Wrong - Too many retries for quick operation
let badRetry = RetryPolicyService(
    strategy: .exponential(retry: 20, duration: .seconds(10))
)
```

### Recommended Configurations

| Operation Type | Strategy | Retry Count | Base Duration | Notes |
|---------------|----------|-------------|---------------|-------|
| Cache access | Constant | 2-3 | 50-100ms | Fast recovery |
| Database query | Constant | 3-5 | 100-500ms | Predictable delays |
| REST API | Exponential | 3-4 | 500ms-1s | Standard backoff |
| GraphQL API | Exponential | 3-5 | 1-2s | Handle complex queries |
| File upload | Exponential + Jitter | 5-7 | 2-5s | Large operations |
| Critical payment | Exponential + Jitter | 5-10 | 1-2s | Maximum reliability |
| Rate-limited API | Constant | 3-5 | Based on rate limit | Respect limits |

## Service Architecture

### Reuse Service Instances

Create retry services at the appropriate scope:

```swift
// ✅ Good - Singleton or service property
class APIClient {
    static let shared = APIClient()
    
    private let retryService = RetryPolicyService(
        strategy: .exponential(retry: 3, duration: .seconds(1))
    )
    
    func fetchUser(id: String) async throws -> User {
        try await retryService.retry {
            try await performFetch(id: id)
        }
    }
}

// ✅ Good - Dependency injection
class DataRepository {
    private let retryService: RetryPolicyService
    
    init(retryService: RetryPolicyService = .default) {
        self.retryService = retryService
    }
}

// ❌ Bad - Creating new instances repeatedly
func fetchData() async throws -> Data {
    let service = RetryPolicyService(...)  // Don't do this!
    return try await service.retry { ... }
}
```

### Organize by Layer

Structure retry services by architectural layer:

```swift
// Network Layer
class NetworkRetryService {
    static let standard = RetryPolicyService(
        strategy: .exponential(retry: 3, duration: .milliseconds(500))
    )
    
    static let critical = RetryPolicyService(
        strategy: .exponential(
            retry: 5,
            jitterFactor: 0.2,
            maxInterval: 60,
            multiplier: 2.0,
            duration: .seconds(1)
        )
    )
}

// Data Layer
class DataRetryService {
    static let cache = RetryPolicyService(
        strategy: .constant(retry: 2, duration: .milliseconds(50))
    )
    
    static let database = RetryPolicyService(
        strategy: .constant(retry: 3, duration: .milliseconds(200))
    )
}

// Usage
class UserRepository {
    func fetchUser(id: String) async throws -> User {
        try await NetworkRetryService.standard.retry {
            try await api.getUser(id: id)
        }
    }
    
    func cacheUser(_ user: User) async throws {
        try await DataRetryService.cache.retry {
            try cache.save(user)
        }
    }
}
```

## Error Handling

### Selective Retry

Don't retry errors that won't benefit from retrying:

```swift
enum APIError: Error {
    case networkFailure       // ✅ Retry
    case serverError         // ✅ Retry (5xx)
    case timeout             // ✅ Retry
    case rateLimited         // ✅ Retry with delay
    case unauthorized        // ❌ Don't retry (401)
    case forbidden           // ❌ Don't retry (403)
    case notFound            // ❌ Don't retry (404)
    case badRequest          // ❌ Don't retry (400)
    case invalidData         // ❌ Don't retry
}

func fetchWithSelectiveRetry() async throws -> Data {
    do {
        return try await retryService.retry({
            try await performRequest()
        }, onFailure: { error in 
            if let error = error as? APIError {
                switch error {
                case .unauthorized, .forbidden, .notFound, .badRequest, .invalidData:
                    // Don't retry client errors
                    throw error
                case .networkFailure, .serverError, .timeout, .rateLimited:
                    // These were already retried
                    throw error
            }
        })
    } catch let error {
        throw error
    }
}
```

## Performance Optimization

### Avoid Over-Retrying

Balance persistence with resource usage:

```swift
// ❌ Bad - Too aggressive
let badService = RetryPolicyService(
    strategy: .constant(retry: 100, duration: .milliseconds(10))
)

// ✅ Good - Reasonable limits
let goodService = RetryPolicyService(
    strategy: .exponential(
        retry: 5,
        maxInterval: 60,
        duration: .seconds(1)
    )
)
```

### Set Appropriate Timeouts

Combine retries with timeouts to prevent indefinite waiting:

```swift
func fetchWithTimeout<T: Sendable>(
    timeout: TimeInterval,
    operation: @Sendable @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await retryService.retry(operation)
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw TimeoutError.exceeded
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
```

## Testing

### Mock Retry Behavior

Create testable retry scenarios:

```swift
actor MockService {
    var failureCount: Int
    private var currentAttempt = 0
    
    init(failureCount: Int) {
        self.failureCount = failureCount
    }
    
    func operation() throws -> String {
        currentAttempt += 1
        if currentAttempt <= failureCount {
            throw MockError.transient
        }
        return "Success"
    }
}

// Test
func testRetrySucceedsAfterFailures() async throws {
    let mock = MockService(failureCount: 2)
    let service = RetryPolicyService(
        strategy: .constant(retry: 3, duration: .milliseconds(10))
    )
    
    let result = try await service.retry {
        try await mock.operation()
    }
    
    XCTAssertEqual(result, "Success")
}
```

### Test Strategy Behavior

Verify retry timing and attempts:

```swift
func testExponentialBackoff() async throws {
    let startTime = Date()
    var attempts = 0
    
    do {
        try await retryService.retry {
            attempts += 1
            throw TestError.failed
        }
    } catch {
        // Expected to fail
    }
    
    let duration = Date().timeIntervalSince(startTime)
    
    XCTAssertEqual(attempts, 4)  // Initial + 3 retries
    XCTAssertGreaterThan(duration, 7.0)  // 1 + 2 + 4 seconds
}
```

## Common Pitfalls

### Don't Retry Non-Idempotent Operations

Be careful with operations that shouldn't be repeated:

```swift
// ❌ Dangerous - May create duplicate payments
func processPayment(amount: Decimal) async throws {
    try await retryService.retry {
        try await paymentGateway.charge(amount)
    }
}

// ✅ Safe - Use idempotency key
func processPayment(amount: Decimal, idempotencyKey: String) async throws {
    try await retryService.retry {
        try await paymentGateway.charge(
            amount: amount,
            idempotencyKey: idempotencyKey
        )
    }
}
```

### Don't Ignore Cancellation

Respect task cancellation:

```swift
// ✅ Good - Check cancellation
try await retryService.retry {
    try Task.checkCancellation()
    return try await operation()
}

// ❌ Bad - Ignores cancellation
try await retryService.retry {
    return try await operation()  // May continue after cancel
}
```

### Don't Nest Retries

Avoid multiple retry layers:

```swift
// ❌ Bad - Nested retries multiply attempts
func fetch() async throws -> Data {
    try await outerRetry.retry {
        try await innerRetry.retry {  // Don't do this!
            try await actualFetch()
        }
    }
}

// ✅ Good - Single retry layer
func fetch() async throws -> Data {
    try await retryService.retry {
        try await actualFetch()
    }
}
```

## See Also

- <doc:quick-start>
- <doc:advanced-retry-strategies>

- ``RetryPolicyService``
