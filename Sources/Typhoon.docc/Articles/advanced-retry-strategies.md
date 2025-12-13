
# Advanced Retry Strategies

Master advanced retry patterns and optimization techniques.

## Overview

This guide covers advanced usage patterns, performance optimization, and sophisticated retry strategies for complex scenarios.

## Strategy Deep Dive

### Understanding Exponential Backoff

Exponential backoff progressively increases wait times to avoid overwhelming recovering services:

```swift
let strategy = RetryStrategy.exponential(
    retry: 5,
    multiplier: 2.0,
    duration: .seconds(1)
)
```

**Calculation:** `delay = baseDuration × multiplier^retryCount`

| Attempt | Calculation | Delay |
|---------|-------------|-------|
| 1 | 1 × 2⁰ | 1s |
| 2 | 1 × 2¹ | 2s |
| 3 | 1 × 2² | 4s |
| 4 | 1 × 2³ | 8s |
| 5 | 1 × 2⁴ | 16s |

**Multiplier effects:**

```swift
// Aggressive backoff (multiplier: 3.0)
// 1s → 3s → 9s → 27s → 81s

// Moderate backoff (multiplier: 1.5)
// 1s → 1.5s → 2.25s → 3.375s → 5.0625s

// Slow backoff (multiplier: 1.2)
// 1s → 1.2s → 1.44s → 1.728s → 2.074s
```

### Jitter: Preventing Thundering Herd

When multiple clients retry simultaneously, they can overwhelm a recovering service. Jitter adds randomization to prevent this:

```swift
let strategy = RetryStrategy.exponentialWithJitter(
    retry: 5,
    jitterFactor: 0.2,                 // ±20% randomization
    maxInterval: .seconds(30),         // Cap at 30 seconds
    multiplier: 2.0,
    duration: .seconds(1)
)
```

**Without jitter:**
```
Client 1: 0s → 1s → 2s → 4s → 8s
Client 2: 0s → 1s → 2s → 4s → 8s
Client 3: 0s → 1s → 2s → 4s → 8s
All hit server simultaneously! 💥
```

**With jitter:**
```
Client 1: 0s → 0.9s → 2.1s → 3.8s → 8.2s
Client 2: 0s → 1.1s → 1.9s → 4.3s → 7.7s
Client 3: 0s → 0.8s → 2.2s → 3.9s → 8.1s
Traffic spread out! ✅
```

### Maximum Interval Capping

Prevent delays from growing unbounded:

```swift
.exponentialWithJitter(
    retry: 10,
    jitterFactor: 0.1,
    maxInterval: .seconds(60),  // Never wait more than 60 seconds
    multiplier: 2.0,
    duration: .seconds(1)
)
```

**Without cap:** 1s → 2s → 4s → 8s → 16s → 32s → 64s → 128s → 256s...

**With 60s cap:** 1s → 2s → 4s → 8s → 16s → 32s → 60s → 60s → 60s...

## Advanced Patterns

### Conditional Retry Logic

Retry only for specific error types:

```swift
enum NetworkError: Error {
    case serverError
    case clientError
    case timeout
    case connectionLost
}

func fetchWithConditionalRetry() async throws -> Data {
    let retryService = RetryPolicyService(
        strategy: .exponential(retry: 3, duration: .seconds(1))
    )
    
    do {
        
        return try await retryService.retry({
            try await performRequest()
        }, onFailure: { error in
            if let error = error as? NetworkError {
                switch error {
                case .serverError, .timeout, .connectionLost:
                    // These errors were already retried
                    return true
                case .clientError:
                    // Don't retry client errors (4xx)
                    return false
                }
            }

            return true
        })
    } catch let error as RetryPolicyError {
        switch error {
        case .retryLimitExceeded:
            // Retry linit exceeded
            throw error
        }
    }
}
```

### Retry with Timeout

Combine retry logic with overall timeout:

```swift
func fetchWithTimeout() async throws -> Data {
    let retryService = RetryPolicyService(
        strategy: .exponential(retry: 5, duration: .seconds(1))
    )
    
    return try await withThrowingTaskGroup(of: Data.self) { group in
        // Add retry task
        group.addTask {
            try await retryService.retry {
                try await performRequest()
            }
        }
        
        // Add timeout task
        group.addTask {
            try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            throw TimeoutError.exceeded
        }
        
        // Return first result or throw first error
        guard let result = try await group.next() else {
            throw TimeoutError.unknown
        }
        
        group.cancelAll()
        return result
    }
}
```

### Adaptive Retry Strategy

Adjust strategy based on error patterns:

```swift
actor AdaptiveRetryService {
    private var consecutiveFailures = 0
    private let maxConsecutiveFailures = 3
    
    func retry<T: Sendable>(_ operation: @Sendable () async throws -> T) async throws -> T {
        let strategy = selectStrategy()
        let retryService = RetryPolicyService(strategy: strategy)
        
        do {
            let result = try await retryService.retry(operation)
            consecutiveFailures = 0
            return result
        } catch {
            consecutiveFailures += 1
            throw error
        }
    }
    
    private func selectStrategy() -> RetryPolicyStrategy {
        if consecutiveFailures >= maxConsecutiveFailures {
            // System under stress - use conservative strategy
            return .exponentialWithJitter(
                retry: 3,
                jitterFactor: 0.3,
                maxInterval: 120,
                multiplier: 3.0,
                duration: .seconds(5)
            )
        } else {
            // Normal operation - use standard strategy
            return .exponential(
                retry: 4,
                multiplier: 2.0,
                duration: .seconds(1)
            )
        }
    }
}
```

### Retry with Progress Tracking

Monitor retry attempts:

```swift
actor RetryProgressTracker {
    var onRetry: ((Int, Error) async -> Void)?
    
    private let maxRetries = 5

    private final class AttemptCounter {
        var count: Int = 0
    }

    func fetchWithProgress<T>(
        operation: @escaping () async throws -> T
    ) async throws -> T {
        
        let counter = AttemptCounter()
        
        let retryService = RetryPolicyService(
            strategy: .exponential(retry: maxRetries, duration: .seconds(1))
        )
        
        return try await retryService.retry {
            counter.count += 1
            
            do {
                return try await operation()
            } catch {
                if counter.count < self.maxRetries {
                    await self.notifyOnRetry(attemptCount: counter.count, error: error)
                }
                
                throw error
            }
        }
    }

    private func notifyOnRetry(attemptCount: Int, error: Error) async {
        await onRetry?(attemptCount, error)
    }
}

// Usage
let tracker = RetryProgressTracker()
tracker.onRetry = { attempt, error in
    print("Retry attempt \(attempt) after error: \(error)")
}

let data = try await tracker.fetchWithProgress {
    try await fetchFromAPI()
}
```

## Performance Optimization

### Choosing the Right Strategy

| Scenario | Strategy | Rationale |
|----------|----------|-----------|
| Fast local operations | Constant (3, 100ms) | Quick retries for transient issues |
| Network requests | Exponential (4, 500ms-1s) | Give service time to recover |
| High-traffic APIs | Exponential with jitter | Prevent synchronized retries |
| Critical operations | Exponential with jitter + cap | Balance persistence with resource usage |
| Rate-limited APIs | Constant with long delay | Respect rate limits |

### Memory Management

Typhoon is designed to be memory-efficient:

```swift
// ✅ Good - Reuse service instance
class DataRepository {
    private let retryService = RetryPolicyService(
        strategy: .exponential(retry: 3, duration: .seconds(1))
    )
    
    func fetchData() async throws -> Data {
        try await retryService.retry {
            try await performFetch()
        }
    }
}

// ❌ Avoid - Creating new instances repeatedly
func fetchData() async throws -> Data {
    let retryService = RetryPolicyService(  // Creates new instance each time
        strategy: .exponential(retry: 3, duration: .seconds(1))
    )
    return try await retryService.retry {
        try await performFetch()
    }
}
```

### Cancellation Support

Typhoon respects task cancellation:

```swift
let task = Task {
    let retryService = RetryPolicyService(
        strategy: .exponential(retry: 10, duration: .seconds(5))
    )
    
    return try await retryService.retry {
        try Task.checkCancellation()  // Respects cancellation
        return try await longRunningOperation()
    }
}

// Cancel after 10 seconds
Task {
    try await Task.sleep(nanoseconds: 10_000_000_000)
    task.cancel()
}
```

## Testing Strategies

### Mock Retry Behavior

```swift
class MockRetryService {
    var shouldSucceedAfter: Int = 2
    private var attemptCount = 0
    
    func simulateRetry() async throws -> String {
        attemptCount += 1
        
        if attemptCount < shouldSucceedAfter {
            throw MockError.transient
        }
        
        return "Success"
    }
}

// Test
let mock = MockRetryService()
mock.shouldSucceedAfter = 3

let retryService = RetryPolicyService(
    strategy: .constant(retry: 5, duration: .milliseconds(10))
)

let result = try await retryService.retry {
    try await mock.simulateRetry()
}

XCTAssertEqual(result, "Success")
```

## See Also

- <doc:QuickStart>
- <doc:BestPractices>
- ``RetryPolicyService``
- ``RetryStrategy``
